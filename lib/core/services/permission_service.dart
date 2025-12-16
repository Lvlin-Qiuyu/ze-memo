import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// 权限管理服务
class PermissionService {
  /// 检查是否需要请求存储权限
  static Future<bool> checkStoragePermission() async {
    if (await Permission.storage.isGranted) {
      return true;
    }
    return false;
  }

  /// 请求存储权限
  static Future<bool> requestStoragePermission(BuildContext context) async {
    try {
      // 检查是否是 Android 11 或更高版本
      bool isAndroid11OrHigher = false;
      try {
        DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        isAndroid11OrHigher = androidInfo.version.sdkInt >= 30;
      } catch (e) {
        // 如果无法获取版本信息，假设需要新权限
        isAndroid11OrHigher = true;
      }

      // 显示权限说明对话框
      bool shouldContinue = await _showStoragePermissionDialog(
        context,
        isAndroid11OrHigher,
      );

      if (!shouldContinue) {
        return false;
      }

      // 请求权限
      bool granted = false;

      // 对于 Android 11+，请求 MANAGE_EXTERNAL_STORAGE
      if (isAndroid11OrHigher) {
        granted = await _requestManageExternalStorage();
      }

      // 如果未获得 MANAGE_EXTERNAL_STORAGE，尝试请求基本存储权限
      if (!granted) {
        granted = await _requestBasicStorage();
      }

      if (!granted) {
        // 如果权限被拒绝，显示设置说明
        _showPermissionDeniedDialog(context, isAndroid11OrHigher);
      }

      return granted;
    } catch (e) {
      debugPrint('请求存储权限失败: $e');
      return false;
    }
  }

  /// 显示存储权限说明对话框
  static Future<bool> _showStoragePermissionDialog(
    BuildContext context,
    bool isAndroid11OrHigher,
  ) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('需要存储权限'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '野火集需要存储权限才能将笔记导出到您的设备下载目录。',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            if (isAndroid11OrHigher) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Android 11+ 用户',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '您需要授予"访问所有文件"权限，这样应用才能将文件保存到系统下载目录。',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '您需要授予存储权限，这样应用才能访问和写入设备存储。',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('授予权限'),
          ),
        ],
      ),
    ) ?? false;
  }

  /// 请求 MANAGE_EXTERNAL_STORAGE 权限
  static Future<bool> _requestManageExternalStorage() async {
    try {
      var status = await Permission.manageExternalStorage.status;

      if (status.isGranted) {
        return true;
      }

      if (status.isPermanentlyDenied) {
        // 权限被永久拒绝，需要引导用户到设置
        await openAppSettings();
        return false;
      }

      // 请求权限
      var result = await Permission.manageExternalStorage.request();
      return result.isGranted;
    } catch (e) {
      debugPrint('请求 MANAGE_EXTERNAL_STORAGE 权限失败: $e');
      return false;
    }
  }

  /// 请求基本存储权限
  static Future<bool> _requestBasicStorage() async {
    try {
      var status = await Permission.storage.status;

      if (status.isGranted) {
        return true;
      }

      if (status.isPermanentlyDenied) {
        // 权限被永久拒绝，需要引导用户到设置
        await openAppSettings();
        return false;
      }

      // 请求权限
      var result = await Permission.storage.request();
      return result.isGranted;
    } catch (e) {
      debugPrint('请求存储权限失败: $e');
      return false;
    }
  }

  /// 显示权限被拒绝的对话框
  static void _showPermissionDeniedDialog(
    BuildContext context,
    bool isAndroid11OrHigher,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('权限被拒绝'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '存储权限被拒绝，导出的文件将保存在应用专用目录中。',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            if (isAndroid11OrHigher) ...[
              const Text(
                '如果您想将文件保存到系统下载目录，请：',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('1. 打开系统设置'),
              const Text('2. 找到"野火集"应用'),
              const Text('3. 权限 > 存储访问'),
              const Text('4. 选择"允许访问所有文件"'),
            ] else ...[
              const Text(
                '如果您想导出文件到系统目录，请：',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('1. 打开系统设置'),
              const Text('2. 找到"野火集"应用'),
              const Text('3. 权限 > 存储'),
              const Text('4. 选择"允许"'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('知道了'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('打开设置'),
          ),
        ],
      ),
    );
  }

  
  /// 检查并请求所需权限
  static Future<bool> checkAndRequestPermissions(BuildContext context) async {
    // 如果已经有权限，直接返回
    if (await Permission.storage.isGranted ||
        await Permission.manageExternalStorage.isGranted) {
      return true;
    }

    // 否则请求权限
    final granted = await requestStoragePermission(context);

    // 如果权限被拒绝，显示提示
    if (!granted && context.mounted) {
      _showPermissionDeniedMessage(context);
    }

    return granted;
  }

  /// 显示权限被拒绝的消息
  static void _showPermissionDeniedMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('导出失败：需要存储权限才能保存文件到下载目录'),
        duration: Duration(seconds: 5),
        action: SnackBarAction(
          label: '设置',
          onPressed: openAppSettings,
        ),
      ),
    );
  }
}