import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';

/// 文件管理器服务
class FileManagerService {
  /// 打开文件
  static Future<void> openFile(String filePath) async {
    try {
      final result = await OpenFilex.open(filePath);
      debugPrint('打开文件结果: ${result.type}, ${result.message}');
    } catch (e) {
      debugPrint('打开文件失败: $e');
      // 如果 open_filex 失败，尝试使用 Android Intent
      if (Platform.isAndroid) {
        await _openFileWithIntent(filePath);
      }
    }
  }

  /// 打开文件夹
  static Future<void> openFolder(String folderPath) async {
    try {
      if (Platform.isAndroid) {
        // Android 使用 Intent 打开文件夹
        await _openFolderWithIntent(folderPath);
      } else if (Platform.isWindows) {
        // Windows 使用 explorer
        await Process.run('explorer', [folderPath]);
      } else if (Platform.isMacOS) {
        // macOS 使用 open
        await Process.run('open', [folderPath]);
      } else if (Platform.isLinux) {
        // Linux 使用 xdg-open
        await Process.run('xdg-open', [folderPath]);
      }
    } catch (e) {
      debugPrint('打开文件夹失败: $e');
    }
  }

  /// 使用 Android Intent 打开文件
  static Future<void> _openFileWithIntent(String filePath) async {
    try {
      final intent = AndroidIntent(
        action: 'android.intent.action.VIEW',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
        data: Uri.file(filePath).toString(),
        type: _getMimeType(filePath),
      );
      await intent.launch();
    } catch (e) {
      debugPrint('使用 Intent 打开文件失败: $e');
    }
  }

  /// 使用 Android Intent 打开文件夹
  static Future<void> _openFolderWithIntent(String folderPath) async {
    try {
      // 尝试使用多种方式打开文件夹
      final intents = [
        // 方法1: 使用 ACTION_VIEW 打开文件夹
        AndroidIntent(
          action: 'android.intent.action.VIEW',
          flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
          data: Uri.directory(folderPath).toString(),
        ),
        // 方法2: 使用文件管理器
        AndroidIntent(
          action: 'android.intent.action.VIEW',
          flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
          data: 'content://com.android.externalstorage.documents/tree/primary%3ADownload',
        ),
        // 方法3: 直接启动下载文件夹
        AndroidIntent(
          action: 'android.intent.action.VIEW',
          flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
          data: 'content://com.android.externalstorage.documents/document/primary%3ADownload',
        ),
      ];

      for (final intent in intents) {
        try {
          await intent.launch();
          break; // 如果成功，退出循环
        } catch (e) {
          debugPrint('Intent 方式失败，尝试下一个: $e');
          continue;
        }
      }
    } catch (e) {
      debugPrint('打开文件夹失败: $e');
    }
  }

  /// 获取文件的 MIME 类型
  static String _getMimeType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'json':
        return 'application/json';
      case 'txt':
        return 'text/plain';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
      case 'docx':
        return 'application/msword';
      case 'xls':
      case 'xlsx':
        return 'application/vnd.ms-excel';
      default:
        return 'application/octet-stream';
    }
  }

  /// 获取推荐安装的文件管理器应用列表
  static List<Map<String, String>> getRecommendedFileManagers() {
    return [
      {
        'name': 'Files by Google',
        'package': 'com.google.android.apps.nbu.files',
        'description': 'Google 官方文件管理器',
      },
      {
        'name': 'Solid Explorer',
        'package': 'pl.solidexplorer2',
        'description': '功能强大的文件管理器',
      },
      {
        'name': 'X-plore File Manager',
        'package': 'com.lonelycatgames.Xplore',
        'description': '双窗口文件管理器',
      },
      {
        'name': 'Total Commander',
        'package': 'com.ghisler.android.TotalCommander',
        'description': '经典文件管理器',
      },
      {
        'name': 'FX File Explorer',
        'package': 'nextapp.fx',
        'description': '简洁的文件管理器',
      },
    ];
  }

  /// 打开应用商店显示文件管理器
  static Future<void> openFileManagerSuggestions(BuildContext context) async {
    final fileManagers = getRecommendedFileManagers();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('推荐安装文件管理器'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '为了更好地查看导出的文件，建议安装以下文件管理器：',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            ...fileManagers.map((fm) => ListTile(
              dense: true,
              leading: const Icon(Icons.folder, color: Colors.blue),
              title: Text(fm['name']!),
              subtitle: Text(fm['description']!),
              onTap: () {
                // 打开 Google Play 商店（实际项目中需要实现）
                Navigator.of(context).pop();
              },
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }
}