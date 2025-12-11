import 'package:flutter/material.dart';
import 'dart:convert';
import '../../data/models/chat_message.dart';
import '../../data/models/classification_result.dart';
import '../../data/services/ai_service.dart';
import '../../data/services/storage_interface.dart';

class ChatProvider with ChangeNotifier {
  final AiService _aiService;
  final IStorageService _storageService;

  List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  ChatProvider({
    required AiService aiService,
    required IStorageService storageService,
  })  : _aiService = aiService,
        _storageService = storageService;

  // 初始化时加载聊天记录
  Future<void> initialize() async {
    await _loadMessages();
  }

  // 加载聊天记录
  Future<void> _loadMessages() async {
    try {
      final messagesJson = await _storageService.getChatMessages();
      _messages = messagesJson.map((json) => ChatMessage.fromJson(json)).toList();
      notifyListeners();
    } catch (e) {
      print('加载聊天记录失败: $e');
    }
  }

  // 保存聊天记录
  Future<void> _saveMessages() async {
    try {
      final messagesJson = _messages.map((message) => message.toJson()).toList();
      await _storageService.saveChatMessages(messagesJson);
    } catch (e) {
      print('保存聊天记录失败: $e');
    }
  }

  // 发送消息
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    // 清除之前的错误消息
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();

    // 创建用户消息
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      isUser: true,
      timestamp: DateTime.now(),
      state: ChatState.idle,
    );

    _messages.add(userMessage);
    notifyListeners();

    try {
      // 立即创建一个loading状态的AI回复消息
      final loadingMessage = ChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        content: '',
        isUser: false,
        timestamp: DateTime.now(),
        state: ChatState.processing,
      );

      _messages.add(loadingMessage);
      notifyListeners();

      ClassificationResult classification;

      // AI分类
      // 获取已有的类别列表
      final existingCategories = await _getExistingCategories();
      classification = await _aiService.classifyNote(content, existingCategories: existingCategories);

      // 更新loading消息为处理中的消息
      final processingMessage = loadingMessage.copyWith(
        content: content,
        classification: classification,
      );

      _messages.removeLast();
      _messages.add(processingMessage);
      notifyListeners();

      // 保存到本地
      final categoryId = classification.effectiveCategoryId;
      final noteFile = await _storageService.addNoteEntry(
        categoryId: categoryId,
        content: content,
        title: classification.displayName,
        description: classification.effectiveDescription,
      );

      if (noteFile != null) {
        // 更新消息状态为成功
        final successMessage = processingMessage.copyWith(
          state: ChatState.success,
        );

        _messages.removeLast();
        _messages.add(successMessage);

        // 如果是新类别，添加系统消息
        if (classification.isNewCategory) {
          final systemMessage = ChatMessage(
            id: (DateTime.now().millisecondsSinceEpoch + 2).toString(),
            content: '已创建新类别"${classification.displayName}"',
            isUser: false,
            timestamp: DateTime.now(),
            state: ChatState.idle,
          );
          _messages.add(systemMessage);
        }
      } else {
        // 更新消息状态为错误
        final errorMessage = processingMessage.copyWith(
          state: ChatState.error,
          error: '保存笔记失败',
        );

        _messages.removeLast();
        _messages.add(errorMessage);
        _errorMessage = '保存笔记失败';
      }
    } catch (e) {
      // 如果有loading消息，先移除它
      if (_messages.isNotEmpty && _messages.last.state == ChatState.processing) {
        _messages.removeLast();
      }

      // 更新消息状态为错误
      final errorMessage = ChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        content: content,
        isUser: false,
        timestamp: DateTime.now(),
        state: ChatState.error,
        error: e.toString(),
      );

      _messages.add(errorMessage);
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      await _saveMessages();  // 保存消息到持久化存储
      notifyListeners();
    }
  }

  // 获取已有的类别列表
  Future<List<String>> _getExistingCategories() async {
    try {
      final noteFiles = await _storageService.getAllNoteFiles();
      return noteFiles.map((file) => file.title).toList();
    } catch (e) {
      print('获取已有类别失败: $e');
      return [];
    }
  }

  // 重试失败的消息
  Future<void> retryMessage(String messageId) async {
    final messageIndex = _messages.indexWhere((msg) => msg.id == messageId);
    if (messageIndex == -1) return;

    final message = _messages[messageIndex];
    if (message.isUser) {
      // 如果是用户消息，重新发送
      await sendMessage(message.content);
    } else {
      // 如果是错误消息，找到对应的用户消息并重新发送
      final userMessageIndex = _messages.lastIndexWhere(
        (msg) => msg.isUser && msg.timestamp.isBefore(message.timestamp),
      );
      if (userMessageIndex != -1) {
        // 移除错误消息
        _messages.removeAt(messageIndex);
        notifyListeners();

        // 重新发送
        await sendMessage(_messages[userMessageIndex].content);
      }
    }
  }

  // 删除消息
  void deleteMessage(String messageId) {
    _messages.removeWhere((msg) => msg.id == messageId);
    notifyListeners();
  }

  // 清空所有消息
  Future<void> clearAllMessages() async {
    _messages.clear();
    _errorMessage = null;
    await _saveMessages();  // 保存空列表，清空持久化存储
    notifyListeners();
  }

  // 清除错误消息
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // 检查是否有API密钥配置
  bool get isApiKeyConfigured => _aiService.isApiKeyConfigured;

  // 测试API连接
  Future<bool> testApiConnection() async {
    try {
      return await _aiService.testConnection();
    } catch (e) {
      _errorMessage = 'API连接测试失败: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // 设置API密钥
  void setApiKey(String apiKey) {
    _aiService.setApiKey(apiKey);
    notifyListeners();
  }



  @override
  void dispose() {
    _aiService.dispose();
    super.dispose();
  }
}