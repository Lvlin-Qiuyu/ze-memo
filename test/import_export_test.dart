import 'package:flutter_test/flutter_test.dart';
import 'package:ze_memo/data/models/note_file.dart';
import 'package:ze_memo/data/models/note_entry.dart';
import 'dart:convert';

void main() {
  group('Import/Export Tests', () {
    test('NoteFile serialization/deserialization', () {
      // 创建测试数据
      final noteFile = NoteFile.create(
        id: 'test-id',
        category: '工作',
        title: '工作笔记',
        description: '工作相关的笔记',
      );

      // 添加测试条目
      final entry1 = NoteEntry(
        id: 'entry-1',
        content: '第一条笔记',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      );
      final entry2 = NoteEntry(
        id: 'entry-2',
        content: '第二条笔记',
        timestamp: DateTime.now(),
      );

      final updatedFile = noteFile
        ..addEntry(entry1)
        ..addEntry(entry2);

      // 序列化
      final json = updatedFile.toJson();
      expect(json, isA<Map<String, dynamic>>());
      expect(json['category'], equals('工作'));
      expect(json['title'], equals('工作笔记'));
      expect(json['entries'], isA<List>());
      expect(json['entries'].length, equals(2));

      // 反序列化
      final deserializedFile = NoteFile.fromJson(json);
      expect(deserializedFile.id, equals(updatedFile.id));
      expect(deserializedFile.category, equals(updatedFile.category));
      expect(deserializedFile.title, equals(updatedFile.title));
      expect(deserializedFile.totalEntries, equals(2));
    });

    test('Import data format validation', () {
      // 创建有效的导入数据
      final validImportData = {
        'exportDate': DateTime.now().toIso8601String(),
        'version': '1.0',
        'totalFiles': 1,
        'totalEntries': 2,
        'noteFiles': [
          {
            'id': 'test-id',
            'category': '测试',
            'title': '测试笔记',
            'description': '测试描述',
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
            'entries': [
              {
                'id': 'entry-1',
                'content': '测试内容1',
                'timestamp': DateTime.now().toIso8601String(),
              },
              {
                'id': 'entry-2',
                'content': '测试内容2',
                'timestamp': DateTime.now().toIso8601String(),
              }
            ],
          }
        ],
      };

      // 验证JSON格式
      final jsonString = jsonEncode(validImportData);
      final decodedJson = jsonDecode(jsonString);
      expect(decodedJson, equals(validImportData));

      // 测试无效格式
      final invalidImportData = {
        'exportDate': DateTime.now().toIso8601String(),
        'version': '1.0',
        // 缺少 noteFiles 字段
      };

      expect(() => _validateImportData(invalidImportData), throwsA(anything));
    });
  });
}

// 简单的验证函数（从ImportExportService复制）
bool _validateImportData(Map<String, dynamic> data) {
  // 检查必要字段
  if (!data.containsKey('noteFiles') || data['noteFiles'] is! List) {
    return false;
  }

  // 检查每个noteFile的格式
  final noteFiles = data['noteFiles'] as List<dynamic>;
  for (final noteFileJson in noteFiles) {
    if (noteFileJson is! Map<String, dynamic>) {
      return false;
    }

    // 检查必要字段
    if (!noteFileJson.containsKey('category') ||
        !noteFileJson.containsKey('entries')) {
      return false;
    }
  }

  return true;
}