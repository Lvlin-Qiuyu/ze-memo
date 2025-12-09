import 'dart:convert';
import 'dart:io';

class FileUtils {
  /// 安全地读取JSON文件
  static Future<Map<String, dynamic>?> readJsonFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return null;
      }

      final content = await file.readAsString(encoding: utf8);
      if (content.isEmpty) {
        return null;
      }

      return jsonDecode(content) as Map<String, dynamic>;
    } catch (e) {
      print('读取JSON文件失败: $e');
      return null;
    }
  }

  /// 安全地写入JSON文件
  static Future<bool> writeJsonFile(String filePath, Map<String, dynamic> data) async {
    try {
      final file = File(filePath);

      // 确保目录存在
      final directory = file.parent;
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // 格式化JSON字符串
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      await file.writeAsString(jsonString, encoding: utf8);

      return true;
    } catch (e) {
      print('写入JSON文件失败: $e');
      return false;
    }
  }

  /// 安全地追加内容到JSON文件
  static Future<bool> appendToJsonFile(
    String filePath,
    String key,
    dynamic value,
  ) async {
    try {
      // 读取现有数据
      final existingData = await readJsonFile(filePath) ?? <String, dynamic>{};

      // 更新数据
      existingData[key] = value;

      // 写回文件
      return await writeJsonFile(filePath, existingData);
    } catch (e) {
      print('追加到JSON文件失败: $e');
      return false;
    }
  }

  /// 检查文件是否存在
  static Future<bool> fileExists(String filePath) async {
    return await File(filePath).exists();
  }

  /// 删除文件
  static Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('删除文件失败: $e');
      return false;
    }
  }

  /// 获取文件大小
  static Future<int> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      print('获取文件大小失败: $e');
      return 0;
    }
  }

  /// 格式化文件大小
  static String formatFileSize(int bytes) {
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

  /// 生成安全的文件名
  static String generateSafeFileName(String fileName) {
    // 移除或替换不安全的字符
    return fileName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
  }

  /// 确保目录存在
  static Future<void> ensureDirectoryExists(String directoryPath) async {
    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
  }
}