import '../models/note_file.dart';
import '../models/note_entry.dart';

/// 存储服务接口
abstract class IStorageService {
  Future<void> initialize();
  Future<List<NoteFile>> getAllNoteFiles();
  Future<NoteFile?> getNoteFileByCategory(String categoryId);
  Future<NoteFile> createNoteFile({
    required String categoryId,
    required String title,
    required String description,
  });
  Future<bool> saveNoteFile(NoteFile noteFile);
  Future<NoteFile?> addNoteEntry({
    required String categoryId,
    required String content,
    String? title,
    String? description,
  });
  Future<bool> deleteNoteFile(String categoryId);
  Future<List<NoteEntry>> searchAllNotes(String query);
  Future<List<String>> getAllCategories();
  Future<Map<String, dynamic>> getStorageStats();
  Future<Map<String, dynamic>?> exportAllNotes();
  Future<bool> importNotes(Map<String, dynamic> importData);
  Future<int> cleanEmptyFiles();
  // 聊天消息相关
  Future<List<Map<String, dynamic>>> getChatMessages();
  Future<void> saveChatMessages(List<Map<String, dynamic>> messages);
}