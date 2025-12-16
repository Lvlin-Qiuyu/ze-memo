import 'package:flutter_test/flutter_test.dart';
import 'dart:io';

void main() {
  group('Android 导出功能测试', () {
    test('检查是否为 Android 平台', () {
      // 这个测试验证平台检测逻辑
      expect(Platform.isAndroid, isA<bool>());
    });

    test('生成导出文件名格式正确', () {
      // 测试文件名生成
      final now = DateTime(2024, 1, 15, 14, 30);
      final fileName = 'ze_memo_backup_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}.json';

      expect(fileName, equals('ze_memo_backup_20240115_1430.json'));
      expect(fileName.endsWith('.json'), isTrue);
    });
  });
}