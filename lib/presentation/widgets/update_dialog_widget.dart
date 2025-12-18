import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_update_provider.dart';
import '../../core/utils/app_update_helper.dart';
import '../../core/config/update_config.dart';

/// 更新对话框
class UpdateDialogWidget extends StatelessWidget {
  const UpdateDialogWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppUpdateProvider>(
      builder: (context, provider, child) {
        return PopScope(
          // 防止用户通过返回键关闭对话框（有更新时）
          canPop: provider.status != UpdateStatus.available,
          child: AlertDialog(
            title: _buildTitle(provider),
            content: SizedBox(
              width: double.maxFinite,
              child: _buildContent(provider),
            ),
            actions: _buildActions(context, provider),
          ),
        );
      },
    );
  }

  /// 构建标题
  Widget _buildTitle(AppUpdateProvider provider) {
    switch (provider.status) {
      case UpdateStatus.checking:
        return const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('检查更新'),
          ],
        );
      case UpdateStatus.available:
        return Row(
          children: [
            const Icon(Icons.system_update, color: Colors.blue),
            const SizedBox(width: 12),
            const Text('发现新版本'),
          ],
        );
      case UpdateStatus.downloading:
        return const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('下载中'),
          ],
        );
      case UpdateStatus.installing:
        return const Row(
          children: [
            Icon(Icons.install_mobile, color: Colors.green),
            SizedBox(width: 12),
            Text('安装中'),
          ],
        );
      case UpdateStatus.error:
        return const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 12),
            Text('更新失败'),
          ],
        );
      default:
        return const Text('系统更新');
    }
  }

  /// 构建内容
  Widget _buildContent(AppUpdateProvider provider) {
    switch (provider.status) {
      case UpdateStatus.checking:
        return const SizedBox(
          height: 60,
          child: Center(
            child: Text('正在检查是否有新版本...'),
          ),
        );
      case UpdateStatus.available:
        return ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 300),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '发现新版本 ${provider.updateInfo?.version}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                provider.updateInfo?.title ?? '',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    provider.updateInfo?.description ?? '暂无更新说明',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        );
      case UpdateStatus.downloading:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '正在下载更新包... ${provider.downloadProgress}%',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: provider.downloadProgress / 100,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 8),
            Text(
              '请稍候，不要关闭应用',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        );
      case UpdateStatus.installing:
        return const SizedBox(
          height: 60,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('正在安装更新...'),
                SizedBox(height: 8),
                Text('请在弹出的安装对话框中确认安装'),
              ],
            ),
          ),
        );
      case UpdateStatus.error:
        return ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 200),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                '更新失败',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    provider.errorMessage ?? '未知错误',
                    style: const TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '请检查网络连接后重试',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        );
      default:
        return const SizedBox(
          height: 60,
          child: Center(
            child: Text('暂无更新'),
          ),
        );
    }
  }

  /// 构建操作按钮
  List<Widget> _buildActions(BuildContext context, AppUpdateProvider provider) {
    switch (provider.status) {
      case UpdateStatus.available:
        return [
          TextButton(
            onPressed: () {
              // 跳过此版本
              provider.skipVersion();
              Navigator.of(context).pop();
            },
            child: const Text('跳过此版本', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              // 稍后更新
              provider.remindLater();
              Navigator.of(context).pop();
            },
            child: const Text('稍后更新'),
          ),
          ElevatedButton(
            onPressed: () {
              // 开始下载
              provider.downloadAndInstall();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('立即更新'),
          ),
        ];
      case UpdateStatus.downloading:
        // 下载中显示取消按钮
        return [
          TextButton(
            onPressed: () {
              provider.cancelDownload();
              // 取消后关闭对话框或返回初始状态
              // 这里选择关闭对话框
              Navigator.of(context).pop();
            },
            child: const Text('取消下载'),
          ),
        ];
      case UpdateStatus.installing:
        // 安装中显示完成按钮
        return [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('知道了'),
          ),
        ];
      case UpdateStatus.error:
        return [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              // 重试 - 不关闭对话框，重新检查更新
              await provider.checkUpdate(
                owner: UpdateConfig.giteeOwner,
                repo: UpdateConfig.giteeRepo,
              );
            },
            child: const Text('重试'),
          ),
        ];
      case UpdateStatus.checking:
        // 检查中显示取消按钮
        return [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('取消'),
          ),
        ];
      case UpdateStatus.noUpdate:
        return [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('知道了'),
          ),
        ];
      default:
        return [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('关闭'),
          ),
        ];
    }
  }
}