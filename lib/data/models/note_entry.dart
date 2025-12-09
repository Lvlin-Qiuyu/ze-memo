class NoteEntry {
  final String id;
  final String content;
  final DateTime timestamp;

  const NoteEntry({
    required this.id,
    required this.content,
    required this.timestamp,
  });

  // 从JSON创建实例
  factory NoteEntry.fromJson(Map<String, dynamic> json) {
    return NoteEntry(
      id: json['id'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // 创建副本
  NoteEntry copyWith({
    String? id,
    String? content,
    DateTime? timestamp,
  }) {
    return NoteEntry(
      id: id ?? this.id,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NoteEntry &&
        other.id == id &&
        other.content == content &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode => id.hashCode ^ content.hashCode ^ timestamp.hashCode;

  @override
  String toString() {
    return 'NoteEntry{id: $id, content: $content, timestamp: $timestamp}';
  }
}