import 'package:flutter/material.dart';
import '../../data/models/classification_result.dart';
import '../../data/services/ai_service.dart';
import '../../data/services/storage_service.dart';

enum ChatState {
  idle,
  sending,
  processing,
  success,
  error,
}

class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final ChatState state;
  final String? error;
  final ClassificationResult? classification;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    required this.state,
    this.error,
    this.classification,
  });

  ChatMessage copyWith({
    String? id,
    String? content,
    bool? isUser,
    DateTime? timestamp,
    ChatState? state,
    String? error,
    ClassificationResult? classification,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      state: state ?? this.state,
      error: error ?? this.error,
      classification: classification ?? this.classification,
    );
  }
}

class ChatProvider with ChangeNotifier {
  final AiService _aiService;
  final StorageService _storageService;

  List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  ChatProvider({
    required AiService aiService,
    required StorageService storageService,
  })  : _aiService = aiService,
        _storageService = storageService;

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

    // 创建处理中的消息
    final processingMessage = ChatMessage(
      id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
      content: content,
      isUser: false,
      timestamp: DateTime.now(),
      state: ChatState.processing,
    );

    _messages.add(userMessage);
    _messages.add(processingMessage);
    notifyListeners();

    try {
      // AI分类
      final classification = await _aiService.classifyNote(content);

      // 保存到本地
      final categoryId = classification.effectiveCategoryId;
      final noteFile = await _storageService.addNoteEntry(
        categoryId: categoryId,
        content: content,
      );

      if (noteFile != null) {
        // 更新消息状态为成功
        final successMessage = processingMessage.copyWith(
          state: ChatState.success,
          classification: classification,
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
      // 更新消息状态为错误
      final errorMessage = processingMessage.copyWith(
        state: ChatState.error,
        error: e.toString(),
      );

      _messages.removeLast();
      _messages.add(errorMessage);
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
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
  void clearAllMessages() {
    _messages.clear();
    _errorMessage = null;
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

  // 获取最近的分类结果
  List<String> getRecentCategories() {
    final recentMessages = _messages
        .where((msg) => !msg.isUser && msg.classification != null)
        .take(5)
        .toList();

    return recentMessages
        .map((msg) => msg.classification!.effectiveCategoryId)
        .toSet()
        .toList();
  }

  // 统计消息数量
  Map<String, int> getMessageStats() {
    final stats = <String, int>{
      'total': _messages.length,
      'user': _messages.where((msg) => msg.isUser).length,
      'bot': _messages.where((msg) => !msg.isUser).length,
      'success': _messages.where((msg) => msg.state == ChatState.success).length,
      'error': _messages.where((msg) => msg.state == ChatState.error).length,
    };

    return stats;
  }

  @override
  void dispose() {
    _aiService.dispose();
    super.dispose();
  }
}