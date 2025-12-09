import 'package:flutter/material.dart';
import '../../data/models/note_file.dart';
import '../../data/models/note_entry.dart';
import '../../data/services/storage_service.dart';

enum NotesViewMode {
  category,
  date,
  search,
}

class NotesProvider with ChangeNotifier {
  final StorageService _storageService;

  List<NoteFile> _noteFiles = [];
  List<NoteFile> get noteFiles => List.unmodifiable(_noteFiles);

  List<NoteEntry> _searchResults = [];
  List<NoteEntry> get searchResults => List.unmodifiable(_searchResults);

  NotesViewMode _viewMode = NotesViewMode.category;
  NotesViewMode get viewMode => _viewMode;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  String? _selectedCategoryId;
  String? get selectedCategoryId => _selectedCategoryId;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // 统计信息
  Map<String, dynamic> _stats = {};
  Map<String, dynamic> get stats => Map.unmodifiable(_stats);

  NotesProvider({required StorageService storageService})
      : _storageService = storageService;

  // 初始化
  Future<void> initialize() async {
    await _loadNotes();
    await _loadStats();
  }

  // 加载所有笔记
  Future<void> _loadNotes() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _noteFiles = await _storageService.getAllNoteFiles();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = '加载笔记失败: ${e.toString()}';
      notifyListeners();
    }
  }

  // 刷新笔记列表
  Future<void> refreshNotes() async {
    await _loadNotes();
    await _loadStats();
  }

  // 切换视图模式
  void setViewMode(NotesViewMode mode) {
    if (_viewMode == mode) return;

    _viewMode = mode;
    _selectedCategoryId = null;
    _searchQuery = '';
    _searchResults.clear();
    notifyListeners();
  }

  // 搜索笔记
  Future<void> searchNotes(String query) async {
    if (query.trim().isEmpty) {
      _searchQuery = '';
      _searchResults.clear();
      notifyListeners();
      return;
    }

    try {
      _searchQuery = query;
      _viewMode = NotesViewMode.search;
      notifyListeners();

      final results = await _storageService.searchAllNotes(query);
      _searchResults = results;
      notifyListeners();
    } catch (e) {
      _errorMessage = '搜索失败: ${e.toString()}';
      notifyListeners();
    }
  }

  // 清除搜索
  void clearSearch() {
    _searchQuery = '';
    _searchResults.clear();
    _viewMode = NotesViewMode.category;
    notifyListeners();
  }

  // 选择类别
  void selectCategory(String categoryId) {
    if (_selectedCategoryId == categoryId) {
      _selectedCategoryId = null;
    } else {
      _selectedCategoryId = categoryId;
      _viewMode = NotesViewMode.category;
    }
    notifyListeners();
  }

  // 获取选中的笔记文件
  NoteFile? get selectedNoteFile {
    if (_selectedCategoryId == null) return null;
    return _noteFiles.firstWhere(
      (file) => file.category == _selectedCategoryId,
      orElse: () => _noteFiles.first,
    );
  }

  // 获取所有类别
  List<String> get allCategories {
    return _noteFiles.map((file) => file.category).toList();
  }

  // 获取按时间排序的所有条目
  List<NoteEntry> get allEntriesByTime {
    final allEntries = <NoteEntry>[];
    for (final file in _noteFiles) {
      allEntries.addAll(file.allEntries);
    }
    allEntries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return allEntries;
  }

  // 获取今日条目
  List<NoteEntry> get todayEntries {
    final today = DateTime.now();
    return allEntriesByTime.where((entry) =>
      entry.timestamp.year == today.year &&
      entry.timestamp.month == today.month &&
      entry.timestamp.day == today.day
    ).toList();
  }

  // 获取本周条目
  List<NoteEntry> get thisWeekEntries {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    return allEntriesByTime.where((entry) =>
      entry.timestamp.isAfter(weekStart)
    ).toList();
  }

  // 删除笔记文件
  Future<bool> deleteNoteFile(String categoryId) async {
    try {
      final success = await _storageService.deleteNoteFile(categoryId);
      if (success) {
        _noteFiles.removeWhere((file) => file.category == categoryId);
        if (_selectedCategoryId == categoryId) {
          _selectedCategoryId = null;
        }
        await _loadStats();
        notifyListeners();
      }
      return success;
    } catch (e) {
      _errorMessage = '删除失败: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // 获取存储统计
  Future<void> _loadStats() async {
    try {
      _stats = await _storageService.getStorageStats();
      notifyListeners();
    } catch (e) {
      print('加载统计信息失败: $e');
    }
  }

  // 导出所有笔记
  Future<Map<String, dynamic>?> exportAllNotes() async {
    try {
      return await _storageService.exportAllNotes();
    } catch (e) {
      _errorMessage = '导出失败: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  // 导入笔记
  Future<bool> importNotes(Map<String, dynamic> importData) async {
    try {
      final success = await _storageService.importNotes(importData);
      if (success) {
        await _loadNotes();
        await _loadStats();
      }
      return success;
    } catch (e) {
      _errorMessage = '导入失败: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // 清理空文件
  Future<int> cleanEmptyFiles() async {
    try {
      final cleanedCount = await _storageService.cleanEmptyFiles();
      if (cleanedCount > 0) {
        await _loadNotes();
        await _loadStats();
      }
      return cleanedCount;
    } catch (e) {
      _errorMessage = '清理失败: ${e.toString()}';
      notifyListeners();
      return 0;
    }
  }

  // 获取类别统计
  Map<String, int> getCategoryStats() {
    final stats = <String, int>{};
    for (final file in _noteFiles) {
      stats[file.category] = file.totalEntries;
    }
    return stats;
  }

  // 获取月度统计
  Map<String, int> getMonthlyStats() {
    final stats = <String, int>{};
    final now = DateTime.now();

    // 初始化最近6个月
    for (int i = 0; i < 6; i++) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthKey = '${month.year}-${month.month.toString().padLeft(2, '0')}';
      stats[monthKey] = 0;
    }

    // 统计每月条目数
    for (final file in _noteFiles) {
      for (final entries in file.entriesByDate.values) {
        for (final entry in entries) {
          final monthKey = '${entry.timestamp.year}-${entry.timestamp.month.toString().padLeft(2, '0')}';
          if (stats.containsKey(monthKey)) {
            stats[monthKey] = stats[monthKey]! + 1;
          }
        }
      }
    }

    return stats;
  }

  // 获取热词统计
  Map<String, int> getHotWords() {
    final wordCount = <String, int>{};
    final stopWords = {'的', '了', '在', '是', '我', '有', '和', '就', '不', '人', '都', '一', '一个', '上', '也', '很', '到', '说', '要', '去', '你', '会', '着', '没有', '看', '好', '自己', '这'};

    for (final file in _noteFiles) {
      for (final entry in file.allEntries) {
        final words = entry.content.split(RegExp(r'[\s，。！？；：、]+'));
        for (final word in words) {
          if (word.length >= 2 && !stopWords.contains(word)) {
            wordCount[word] = (wordCount[word] ?? 0) + 1;
          }
        }
      }
    }

    // 返回前20个热词
    final sortedWords = wordCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sortedWords.take(20));
  }

  // 清除错误
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}