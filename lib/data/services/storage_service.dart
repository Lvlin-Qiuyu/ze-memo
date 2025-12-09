import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/note_file.dart';
import '../models/note_entry.dart';
import '../../core/utils/file_utils.dart';

class StorageService {
  static const String _notesFolderName = 'notes';
  late final Directory _notesDirectory;
  final Uuid _uuid = const Uuid();

  // 初始化存储服务
  Future<void> initialize() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      _notesDirectory = Directory('${appDir.path}/$_notesFolderName');
      await FileUtils.ensureDirectoryExists(_notesDirectory.path);
      print('存储服务初始化成功: ${_notesDirectory.path}');
    } catch (e) {
      print('存储服务初始化失败: $e');
      rethrow;
    }
  }

  // 获取笔记文件路径
  String _getNoteFilePath(String categoryId) {
    final fileName = '${FileUtils.generateSafeFileName(categoryId)}.json';
    return '${_notesDirectory.path}/$fileName';
  }

  // 获取所有笔记文件
  Future<List<NoteFile>> getAllNoteFiles() async {
    try {
      final files = await _notesDirectory.list().where(
        (entity) => entity is File && entity.path.endsWith('.json')
      ).cast<File>().toList();

      final noteFiles = <NoteFile>[];
      for (final file in files) {
        final jsonData = await FileUtils.readJsonFile(file.path);
        if (jsonData != null) {
          try {
            final noteFile = NoteFile.fromJson(jsonData);
            noteFiles.add(noteFile);
          } catch (e) {
            print('解析笔记文件失败 ${file.path}: $e');
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
      final filePath = _getNoteFilePath(categoryId);
      final jsonData = await FileUtils.readJsonFile(filePath);

      if (jsonData != null) {
        return NoteFile.fromJson(jsonData);
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

      final filePath = _getNoteFilePath(categoryId);
      final success = await FileUtils.writeJsonFile(filePath, noteFile.toJson());

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
      final filePath = _getNoteFilePath(noteFile.category);
      return await FileUtils.writeJsonFile(filePath, noteFile.toJson());
    } catch (e) {
      print('保存笔记文件失败: $e');
      return false;
    }
  }

  // 添加笔记条目
  Future<NoteFile?> addNoteEntry({
    required String categoryId,
    required String content,
  }) async {
    try {
      // 获取或创建笔记文件
      NoteFile? noteFile = await getNoteFileByCategory(categoryId);

      if (noteFile == null) {
        // 创建新的笔记文件
        noteFile = await createNoteFile(
          categoryId: categoryId,
          title: _getDefaultTitle(categoryId),
          description: _getDefaultDescription(categoryId),
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
      final filePath = _getNoteFilePath(categoryId);
      return await FileUtils.deleteFile(filePath);
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
        final filePath = _getNoteFilePath(file.category);
        totalSize += await FileUtils.getFileSize(filePath);
      }

      return {
        'totalFiles': noteFiles.length,
        'totalEntries': totalEntries,
        'totalSize': totalSize,
        'totalSizeFormatted': FileUtils.formatFileSize(totalSize),
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

  // 获取默认标题
  String _getDefaultTitle(String categoryId) {
    final year = DateTime.now().year;
    switch (categoryId.toLowerCase()) {
      case 'work':
        return '$year年工作笔记';
      case 'study':
        return '$year年学习笔记';
      case 'life':
        return '$year年生活笔记';
      default:
        return '$year年${categoryId}笔记';
    }
  }

  // 获取默认描述
  String _getDefaultDescription(String categoryId) {
    switch (categoryId.toLowerCase()) {
      case 'work':
        return '所有与工作相关的笔记';
      case 'study':
        return '学习笔记、读书心得、知识整理';
      case 'life':
        return '日常记录、生活感悟';
      default:
        return '关于$categoryId的笔记';
    }
  }
}