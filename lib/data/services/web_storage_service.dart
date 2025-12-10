import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/note_file.dart';
import '../models/note_entry.dart';
import 'storage_interface.dart';

/// Web平台的存储服务
class WebStorageService implements IStorageService {
  static const String _notesPrefix = 'notes_';
  final Uuid _uuid = const Uuid();

  // 初始化存储服务
  Future<void> initialize() async {
    print('Web存储服务初始化成功');
  }

  // 获取笔记文件路径（转换为SharedPreferences的key）
  String _getNoteFileKey(String categoryId) {
    final safeName = _generateSafeFileName(categoryId);
    return '$_notesPrefix$safeName';
  }

  // 获取所有笔记文件
  Future<List<NoteFile>> getAllNoteFiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final noteFiles = <NoteFile>[];

      for (final key in keys) {
        if (key.startsWith(_notesPrefix)) {
          final jsonData = prefs.getString(key);
          if (jsonData != null) {
            try {
              final noteFile = NoteFile.fromJson(jsonDecode(jsonData));
              noteFiles.add(noteFile);
            } catch (e) {
              print('解析笔记文件失败 $key: $e');
            }
          }
        }
      }

      // 按更新时间排序，最新的在前面
      noteFiles.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return noteFiles;
    } catch (e) {
      print('获取所有笔记文件失败: $e');
      return [];
    }
  }

  // 根据类别获取笔记文件
  Future<NoteFile?> getNoteFileByCategory(String categoryId) async {
    try {
      final key = _getNoteFileKey(categoryId);
      final prefs = await SharedPreferences.getInstance();
      final jsonData = prefs.getString(key);

      if (jsonData != null) {
        return NoteFile.fromJson(jsonDecode(jsonData));
      }
      return null;
    } catch (e) {
      print('获取笔记文件失败 $categoryId: $e');
      return null;
    }
  }

  // 创建新的笔记文件
  Future<NoteFile> createNoteFile({
    required String categoryId,
    required String title,
    required String description,
  }) async {
    try {
      final id = _uuid.v4();
      final noteFile = NoteFile.create(
        id: id,
        category: categoryId,
        title: title,
        description: description,
      );

      final key = _getNoteFileKey(categoryId);
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setString(key, jsonEncode(noteFile.toJson()));

      if (!success) {
        throw Exception('创建笔记文件失败');
      }

      return noteFile;
    } catch (e) {
      print('创建笔记文件失败: $e');
      rethrow;
    }
  }

  // 保存笔记文件
  Future<bool> saveNoteFile(NoteFile noteFile) async {
    try {
      final key = _getNoteFileKey(noteFile.category);
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(key, jsonEncode(noteFile.toJson()));
    } catch (e) {
      print('保存笔记文件失败: $e');
      return false;
    }
  }

  // 添加笔记条目
  Future<NoteFile?> addNoteEntry({
    required String categoryId,
    required String content,
    String? title,
    String? description,
  }) async {
    try {
      // 获取或创建笔记文件
      NoteFile? noteFile = await getNoteFileByCategory(categoryId);

      if (noteFile == null) {
        // 创建新的笔记文件
        // 使用传入的标题和描述，如果没有传入则使用类别名称
        noteFile = await createNoteFile(
          categoryId: categoryId,
          title: title ?? categoryId,
          description: description ?? '',
        );
      }

      // 创建新的条目
      final entry = NoteEntry(
        id: _uuid.v4(),
        content: content,
        timestamp: DateTime.now(),
      );

      // 添加条目到笔记文件
      final updatedNoteFile = noteFile.addEntry(entry);

      // 保存更新后的文件
      final success = await saveNoteFile(updatedNoteFile);

      if (!success) {
        throw Exception('保存笔记文件失败');
      }

      return updatedNoteFile;
    } catch (e) {
      print('添加笔记条目失败: $e');
      return null;
    }
  }

  // 删除笔记文件
  Future<bool> deleteNoteFile(String categoryId) async {
    try {
      final key = _getNoteFileKey(categoryId);
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(key);
    } catch (e) {
      print('删除笔记文件失败: $e');
      return false;
    }
  }

  // 搜索所有笔记
  Future<List<NoteEntry>> searchAllNotes(String query) async {
    try {
      final allNoteFiles = await getAllNoteFiles();
      final allResults = <NoteEntry>[];

      for (final noteFile in allNoteFiles) {
        final results = noteFile.searchEntries(query);
        allResults.addAll(results);
      }

      // 按时间排序
      allResults.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return allResults;
    } catch (e) {
      print('搜索笔记失败: $e');
      return [];
    }
  }

  // 获取所有类别
  Future<List<String>> getAllCategories() async {
    try {
      final noteFiles = await getAllNoteFiles();
      final categories = noteFiles.map((file) => file.category).toList();
      return categories;
    } catch (e) {
      print('获取所有类别失败: $e');
      return [];
    }
  }

  // 获取存储统计信息
  Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final noteFiles = await getAllNoteFiles();
      int totalEntries = 0;
      int totalSize = 0;

      for (final file in noteFiles) {
        totalEntries += file.totalEntries;
        final key = _getNoteFileKey(file.category);
        final prefs = await SharedPreferences.getInstance();
        final jsonData = prefs.getString(key);
        if (jsonData != null) {
          totalSize += jsonData.length;
        }
      }

      return {
        'totalFiles': noteFiles.length,
        'totalEntries': totalEntries,
        'totalSize': totalSize,
        'totalSizeFormatted': _formatFileSize(totalSize),
      };
    } catch (e) {
      print('获取存储统计失败: $e');
      return {
        'totalFiles': 0,
        'totalEntries': 0,
        'totalSize': 0,
        'totalSizeFormatted': '0 B',
      };
    }
  }

  // 导出所有笔记
  Future<Map<String, dynamic>?> exportAllNotes() async {
    try {
      final noteFiles = await getAllNoteFiles();
      final exportData = {
        'exportDate': DateTime.now().toIso8601String(),
        'version': '1.0',
        'noteFiles': noteFiles.map((file) => file.toJson()).toList(),
      };
      return exportData;
    } catch (e) {
      print('导出笔记失败: $e');
      return null;
    }
  }

  // 导入笔记
  Future<bool> importNotes(Map<String, dynamic> importData) async {
    try {
      final noteFilesJson = importData['noteFiles'] as List<dynamic>;

      for (final noteFileJson in noteFilesJson) {
        final noteFile = NoteFile.fromJson(noteFileJson as Map<String, dynamic>);
        await saveNoteFile(noteFile);
      }

      return true;
    } catch (e) {
      print('导入笔记失败: $e');
      return false;
    }
  }

  // 清理空文件
  Future<int> cleanEmptyFiles() async {
    try {
      final noteFiles = await getAllNoteFiles();
      int cleanedCount = 0;

      for (final noteFile in noteFiles) {
        if (noteFile.totalEntries == 0) {
          final success = await deleteNoteFile(noteFile.category);
          if (success) {
            cleanedCount++;
          }
        }
      }

      return cleanedCount;
    } catch (e) {
      print('清理空文件失败: $e');
      return 0;
    }
  }

  // 生成安全的文件名
  String _generateSafeFileName(String fileName) {
    return fileName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
  }

  // 格式化文件大小
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  // 获取聊天消息
  @override
  Future<List<Map<String, dynamic>>> getChatMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = prefs.getString('chat_messages');
      if (messagesJson != null) {
        final data = jsonDecode(messagesJson);
        if (data['messages'] != null) {
          return List<Map<String, dynamic>>.from(data['messages']);
        }
      }
      return [];
    } catch (e) {
      print('获取聊天消息失败: $e');
      return [];
    }
  }

  // 保存聊天消息
  @override
  Future<void> saveChatMessages(List<Map<String, dynamic>> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'messages': messages,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      await prefs.setString('chat_messages', jsonEncode(data));
    } catch (e) {
      print('保存聊天消息失败: $e');
    }
  }
}