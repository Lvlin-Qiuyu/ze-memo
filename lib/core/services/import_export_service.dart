import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/note_file.dart';
import '../../data/models/note_entry.dart';
import 'android_downloads_service.dart';
import 'permission_service.dart';
import 'file_manager_service.dart';

/// 导入导出服务类
class ImportExportService {
  /// 获取下载目录路径
  static Future<Directory?> getDownloadDirectory() async {
    try {
      Directory? downloadDir;

      if (Platform.isAndroid) {
        // 对于 Android，请求存储权限后尝试访问 Downloads 目录
        // 首先检查权限
        var storagePermission = Permission.storage;
        var managePermission = Permission.manageExternalStorage;

        // 对于 Android 11+，请求 MANAGE_EXTERNAL_STORAGE 权限
        if (await managePermission.status.isGranted) {
          // 有完整存储权限，直接访问系统下载目录
          final downloadPath = '/storage/emulated/0/Download';
          downloadDir = Directory(downloadPath);
        } else if (await storagePermission.status.isGranted) {
          // 有基本存储权限，尝试访问 Downloads 目录
          final downloadPath = '/storage/emulated/0/Download';
          downloadDir = Directory(downloadPath);

          // 如果无法访问，回退到应用外部存储目录
          if (!await downloadDir.exists()) {
            final externalDir = await getExternalStorageDirectory();
            if (externalDir != null) {
              // 使用 /storage/emulated/0/Android/data/package.name/files/Download
              final pathSegments = externalDir.path.split('/');
              final newPath = '/storage/emulated/0/Android/data/${pathSegments[pathSegments.length - 2]}/files/Download';
              downloadDir = Directory(newPath);
            }
          }
        } else {
          // 尝试请求权限
          await Permission.storage.request();
          await Permission.manageExternalStorage.request();

          // 重新检查权限
          if (await managePermission.status.isGranted || await storagePermission.status.isGranted) {
            return await getDownloadDirectory();
          }

          // 如果没有权限，使用应用外部存储目录
          final externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            final pathSegments = externalDir.path.split('/');
            final newPath = '/storage/emulated/0/Android/data/${pathSegments[pathSegments.length - 2]}/files/Download';
            downloadDir = Directory(newPath);
          }
        }
      } else if (Platform.isIOS) {
        // iOS 使用应用文档目录下的 Downloads 文件夹
        final appDir = await getApplicationDocumentsDirectory();
        downloadDir = Directory('${appDir.path}/Downloads');
      } else if (Platform.isWindows) {
        // Windows 下载目录
        final home = Platform.environment['USERPROFILE'];
        if (home != null) {
          downloadDir = Directory('$home\\Downloads');
        }
      } else if (Platform.isMacOS || Platform.isLinux) {
        // macOS/Linux 下载目录
        final home = Platform.environment['HOME'];
        if (home != null) {
          downloadDir = Directory('$home/Downloads');
        }
      }

      // 创建目录（如果不存在）
      if (downloadDir != null && !await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      return downloadDir;
    } catch (e) {
      debugPrint('获取下载目录失败: $e');

      // 回退方案：使用应用文档目录
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final fallbackDir = Directory('${appDir.path}/Downloads');
        if (!await fallbackDir.exists()) {
          await fallbackDir.create(recursive: true);
        }
        return fallbackDir;
      } catch (e) {
        debugPrint('获取应用文档目录失败: $e');
        return null;
      }
    }
  }

  /// 导出笔记到文件
  static Future<bool> exportNotesToFile({
    required List<NoteFile> noteFiles,
    required BuildContext context,
  }) async {
    try {
      // 准备导出数据
      // 计算实际的笔记数量
      int totalEntries = 0;
      for (final noteFile in noteFiles) {
        totalEntries += noteFile.totalEntries;
      }

      final exportData = {
        'exportDate': DateTime.now().toIso8601String(),
        'version': '1.0',
        'totalFiles': noteFiles.length,
        'totalEntries': totalEntries,
        'noteFiles': noteFiles.map((file) => file.toJson()).toList(),
      };

      // 将数据转换为格式化的JSON字符串
      final jsonString = JsonEncoder.withIndent('  ').convert(exportData);

      // 生成默认文件名
      final now = DateTime.now();
      final fileName = 'ze_memo_backup_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}.json';

      // 如果是 Android，先请求权限然后使用专门的下载服务
      if (Platform.isAndroid) {
        // 请求必要的存储权限
        final hasPermission = await PermissionService.checkAndRequestPermissions(context);

        // 如果没有权限，直接返回失败
        if (!hasPermission) {
          return false;
        }

        return await AndroidDownloadsService.saveToDownloads(
          fileName: fileName,
          content: jsonString,
          context: context,
        );
      }

      // 其他平台使用原有逻辑
      final downloadDir = await getDownloadDirectory();
      if (downloadDir == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('无法访问下载目录')),
          );
        }
        return false;
      }

      // 确保目录存在
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      // 保存到下载目录
      final file = File('${downloadDir.path}/$fileName');
      await file.writeAsString(jsonString, encoding: utf8);

      // 显示成功信息
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导出成功：文件已保存到下载目录\n${file.path}'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: '查看',
              onPressed: () {
                // 根据平台选择不同的查看方式
                if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
                  FileManagerService.openFolder(downloadDir.path);
                } else {
                  FileManagerService.openFile(file.path);
                }
              },
            ),
          ),
        );
      }

      return true;
    } catch (e) {
      debugPrint('导出失败: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败：${e.toString()}')),
        );
      }
      return false;
    }
  }

  /// 从文件导入笔记
  static Future<Map<String, dynamic>?> importNotesFromFile({
    required BuildContext context,
  }) async {
    try {
      // 选择文件
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: '选择笔记备份文件',
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return null; // 用户取消了选择
      }

      PlatformFile platformFile = result.files.first;

      // 确保文件是 JSON 文件
      if (!platformFile.extension!.toLowerCase().contains('json')) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('请选择 JSON 格式的备份文件')),
          );
        }
        return null;
      }

      String content;

      // 读取文件内容
      if (platformFile.bytes != null) {
        // 从字节读取（Web 或某些情况）
        content = utf8.decode(platformFile.bytes!);
      } else if (platformFile.path != null) {
        // 从文件路径读取（移动端或桌面端）
        final file = File(platformFile.path!);
        content = await file.readAsString(encoding: utf8);
      } else {
        throw Exception('无法读取文件内容');
      }

      // 检查内容是否为空
      if (content.trim().isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('文件内容为空')),
          );
        }
        return null;
      }

      // 解析 JSON
      Map<String, dynamic> importData;
      try {
        importData = jsonDecode(content) as Map<String, dynamic>;
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('JSON 解析失败：${e.toString()}')),
          );
        }
        return null;
      }

      // 验证数据格式
      if (!_validateImportData(importData)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('无效的备份文件格式')),
          );
        }
        return null;
      }

      // 显示导入摘要
      if (context.mounted) {
        final noteFiles = importData['noteFiles'] as List<dynamic>;

        // 计算实际的笔记数量
        int totalEntries = 0;
        for (final noteFileJson in noteFiles) {
          if (noteFileJson is Map<String, dynamic> &&
              noteFileJson.containsKey('entriesByDate')) {
            final entriesByDate = noteFileJson['entriesByDate'] as Map<String, dynamic>;
            for (final dateEntries in entriesByDate.values) {
              if (dateEntries is List) {
                totalEntries += dateEntries.length;
              }
            }
          }
        }

        final exportDate = importData['exportDate'] ?? '未知';

        final shouldImport = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('导入笔记'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('备份文件：${platformFile.name}'),
                const SizedBox(height: 8),
                Text('导出时间：${_formatDateTime(DateTime.tryParse(exportDate))}'),
                const SizedBox(height: 8),
                Text('包含 ${noteFiles.length} 个笔记类别'),
                Text('共 $totalEntries 条笔记'),
                const SizedBox(height: 16),
                const Text(
                  '注意：导入的笔记将添加到现有笔记中，不会覆盖现有数据。',
                  style: TextStyle(fontSize: 12, color: Colors.orange),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('导入'),
              ),
            ],
          ),
        );

        if (shouldImport != true) {
          return null;
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('正在导入...')),
        );
      }

      return importData;
    } catch (e) {
      debugPrint('导入失败: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败：${e.toString()}')),
        );
      }
      return null;
    }
  }

  /// 验证导入数据的格式
  static bool _validateImportData(Map<String, dynamic> data) {
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

      // 检查必要字段 - NoteFile 模型使用 entriesByDate 而不是 entries
      if (!noteFileJson.containsKey('category') ||
          !noteFileJson.containsKey('entriesByDate')) {
        return false;
      }

      // 验证 entriesByDate 的结构
      final entriesByDate = noteFileJson['entriesByDate'] as Map<String, dynamic>?;
      if (entriesByDate == null) {
        return false;
      }

      // 检查每个日期条目
      for (final dateEntries in entriesByDate.values) {
        if (dateEntries is! List) {
          return false;
        }
        // 检查每个条目是否有必要的字段
        for (final entry in dateEntries) {
          if (entry is! Map<String, dynamic>) {
            return false;
          }
          if (!entry.containsKey('id') ||
              !entry.containsKey('content') ||
              !entry.containsKey('timestamp')) {
            return false;
          }
        }
      }
    }

    return true;
  }

  /// 格式化日期时间
  static String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '未知';

    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
           '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  
  /// 分享文件
  static Future<void> _shareFile(File file) async {
    try {
      await Share.shareXFiles(
        [XFile(file.path, name: file.path.split('/').last)],
        subject: '野火集笔记备份',
        text: '这是我的笔记备份文件，包含${DateTime.now().toString().split(' ')[0]}导出的所有笔记数据',
      );
    } catch (e) {
      debugPrint('分享失败: $e');
    }
  }
}