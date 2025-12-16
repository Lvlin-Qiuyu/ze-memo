import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'file_manager_service.dart';

/// Android 下载目录专用服务
class AndroidDownloadsService {
  /// 使用 MediaStore API 保存文件到系统下载目录
  /// 由于 Flutter 原生不支持 MediaStore，这里提供一个替代方案
  static Future<bool> saveToDownloads({
    required String fileName,
    required String content,
    required BuildContext context,
  }) async {
    try {
      // 检查 Android 版本
      if (!Platform.isAndroid) {
        return false;
      }

      // 尝试多种方法保存到下载目录
      bool success = false;
      String? savedPath;

      // 方法1: 尝试使用 MANAGE_EXTERNAL_STORAGE 权限
      if (await _tryManageStoragePermission()) {
        try {
          final downloadPath = '/storage/emulated/0/Download';
          final downloadDir = Directory(downloadPath);
          if (await downloadDir.exists()) {
            final file = File('$downloadPath/$fileName');
            await file.writeAsString(content);
            savedPath = file.path;
            success = true;
          }
        } catch (e) {
          debugPrint('使用 MANAGE_EXTERNAL_STORAGE 失败: $e');
        }
      }

      // 方法2: 尝试使用 WRITE_EXTERNAL_STORAGE 权限
      if (!success && await _tryStoragePermission()) {
        try {
          final downloadPath = '/storage/emulated/0/Download';
          final downloadDir = Directory(downloadPath);
          if (await downloadDir.exists()) {
            final file = File('$downloadPath/$fileName');
            await file.writeAsString(content);
            savedPath = file.path;
            success = true;
          }
        } catch (e) {
          debugPrint('使用 WRITE_EXTERNAL_STORAGE 失败: $e');
        }
      }

      // 如果所有方法都失败了，不进行保存，直接返回失败
      if (!success) {
        debugPrint('无法访问存储，所有权限都被拒绝');
      }

      // 显示结果
      if (context.mounted) {
        if (success && savedPath != null) {
          String message;
          VoidCallback? viewAction;

          if (savedPath != null && savedPath.contains('/storage/emulated/0/Download')) {
            message = '导出成功！文件已保存到系统下载目录\n$savedPath';
            // 直接打开下载文件夹
            viewAction = () => FileManagerService.openFolder('/storage/emulated/0/Download');
          } else if (savedPath != null && savedPath.contains('/Android/data/')) {
            message = '导出成功！文件已保存到应用下载目录\n$savedPath';
            // 直接打开应用下载文件夹
            final folderPath = savedPath.substring(0, savedPath.lastIndexOf('/'));
            viewAction = () => FileManagerService.openFolder(folderPath);
          } else {
            message = '导出成功！文件已保存到应用存储目录\n${savedPath ?? ''}';
            // 直接打开文件所在文件夹
            if (savedPath != null) {
              final folderPath = savedPath.substring(0, savedPath.lastIndexOf('/'));
              viewAction = () => FileManagerService.openFolder(folderPath);
            }
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              duration: const Duration(seconds: 6),
              action: viewAction != null
                ? SnackBarAction(
                    label: '查看',
                    onPressed: viewAction,
                  )
                : null,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('导出失败：无法访问存储')),
          );
        }
      }

      return success;
    } catch (e) {
      debugPrint('保存到下载目录失败: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败：${e.toString()}')),
        );
      }
      return false;
    }
  }

  /// 尝试获取 MANAGE_EXTERNAL_STORAGE 权限
  static Future<bool> _tryManageStoragePermission() async {
    try {
      var permission = Permission.manageExternalStorage;

      // 检查权限状态
      if (await permission.isGranted) {
        return true;
      }

      // 尝试请求权限
      var result = await permission.request();

      // 检查是否授予了权限
      return result.isGranted;
    } catch (e) {
      debugPrint('请求 MANAGE_EXTERNAL_STORAGE 权限失败: $e');
      return false;
    }
  }

  /// 尝试获取 WRITE_EXTERNAL_STORAGE 权限
  static Future<bool> _tryStoragePermission() async {
    try {
      var permission = Permission.storage;

      // 检查权限状态
      if (await permission.isGranted) {
        return true;
      }

      // 尝试请求权限
      var result = await permission.request();

      // 检查是否授予了权限
      return result.isGranted;
    } catch (e) {
      debugPrint('请求存储权限失败: $e');
      return false;
    }
  }

  
  
  /// 显示权限说明对话框
  static Future<bool> showPermissionDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('需要存储权限'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '为了将笔记导出到系统下载目录，应用需要以下权限：\n',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('• 访问外部存储权限'),
            Text('• 管理所有文件权限（Android 11+）\n'),
            Text(
              '授予权限后，导出的文件将直接保存在系统下载目录中，方便您查看和管理。',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop(true);

              // 打开应用设置页面，让用户手动授予权限
              await openAppSettings();
            },
            child: const Text('去设置'),
          ),
        ],
      ),
    ) ?? false;
  }
}