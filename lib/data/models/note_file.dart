import 'note_entry.dart';

class NoteFile {
  final String id;
  final String category;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, List<NoteEntry>> entriesByDate;

  const NoteFile({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    required this.entriesByDate,
  });

  // 从JSON创建实例
  factory NoteFile.fromJson(Map<String, dynamic> json) {
    final entriesByDateJson = json['entriesByDate'] as Map<String, dynamic>;
    final entriesByDate = <String, List<NoteEntry>>{};

    entriesByDateJson.forEach((date, entries) {
      final entriesList = (entries as List)
          .map((entry) => NoteEntry.fromJson(entry as Map<String, dynamic>))
          .toList();
      entriesByDate[date] = entriesList;
    });

    return NoteFile(
      id: json['id'] as String,
      category: json['category'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      entriesByDate: entriesByDate,
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    final entriesByDateJson = <String, dynamic>{};
    entriesByDate.forEach((date, entries) {
      entriesByDateJson[date] = entries.map((entry) => entry.toJson()).toList();
    });

    return {
      'id': id,
      'category': category,
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'entriesByDate': entriesByDateJson,
    };
  }

  // 创建新实例
  factory NoteFile.create({
    required String id,
    required String category,
    required String title,
    required String description,
  }) {
    final now = DateTime.now();
    return NoteFile(
      id: id,
      category: category,
      title: title,
      description: description,
      createdAt: now,
      updatedAt: now,
      entriesByDate: {},
    );
  }

  // 添加笔记条目
  NoteFile addEntry(NoteEntry entry) {
    final dateKey = entry.timestamp.toIso8601String().substring(0, 10); // YYYY-MM-DD
    final newEntriesByDate = Map<String, List<NoteEntry>>.from(entriesByDate);

    if (newEntriesByDate.containsKey(dateKey)) {
      final entries = List<NoteEntry>.from(newEntriesByDate[dateKey]!);
      entries.add(entry);
      // 按时间排序，最新的在前面
      entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      newEntriesByDate[dateKey] = entries;
    } else {
      newEntriesByDate[dateKey] = [entry];
    }

    return copyWith(
      updatedAt: DateTime.now(),
      entriesByDate: newEntriesByDate,
    );
  }

  // 获取所有条目
  List<NoteEntry> get allEntries {
    final allEntries = <NoteEntry>[];
    for (final entries in entriesByDate.values) {
      allEntries.addAll(entries);
    }
    // 按时间排序，最新的在前面
    allEntries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return allEntries;
  }

  // 获取条目总数
  int get totalEntries {
    int count = 0;
    for (final entries in entriesByDate.values) {
      count += entries.length;
    }
    return count;
  }

  // 获取最近的条目
  NoteEntry? get latestEntry {
    if (allEntries.isEmpty) return null;
    return allEntries.first;
  }

  // 检查是否有特定日期的条目
  bool hasEntriesForDate(DateTime date) {
    final dateKey = date.toIso8601String().substring(0, 10);
    return entriesByDate.containsKey(dateKey) && entriesByDate[dateKey]!.isNotEmpty;
  }

  // 获取特定日期的条目
  List<NoteEntry> getEntriesForDate(DateTime date) {
    final dateKey = date.toIso8601String().substring(0, 10);
    return entriesByDate[dateKey] ?? [];
  }

  // 搜索条目
  List<NoteEntry> searchEntries(String query) {
    if (query.isEmpty) return allEntries;

    final lowerQuery = query.toLowerCase();
    return allEntries.where((entry) =>
      entry.content.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  // 创建副本
  NoteFile copyWith({
    String? id,
    String? category,
    String? title,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, List<NoteEntry>>? entriesByDate,
  }) {
    return NoteFile(
      id: id ?? this.id,
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      entriesByDate: entriesByDate ?? this.entriesByDate,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NoteFile &&
        other.id == id &&
        other.category == category &&
        other.title == title &&
        other.description == description &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        category.hashCode ^
        title.hashCode ^
        description.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }

  @override
  String toString() {
    return 'NoteFile{id: $id, category: $category, title: $title, entriesCount: $totalEntries}';
  }
}