import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../presentation/providers/app_update_provider.dart';
import '../../presentation/widgets/update_dialog_widget.dart';

/// 应用更新帮助类
class AppUpdateHelper {
  /// 显示更新对话框
  static Future<void> showUpdateDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false, // 防止点击外部关闭
      builder: (context) => const UpdateDialogWidget(),
    );
  }

  /// 检查更新并显示对话框
  /// [owner]: Gitee 仓库所有者
  /// [repo]: Gitee 仓库名称
  /// [showNoUpdateDialog]: 是否在无更新时显示提示
  /// [isManual]: 是否手动检查
  static Future<void> checkAndShowUpdate(
    BuildContext context, {
    required String owner,
    required String repo,
    bool showNoUpdateDialog = false,
    bool isManual = false,
  }) async {
    final provider = Provider.of<AppUpdateProvider>(context, listen: false);

    try {
      // 初始化更新服务
      await provider.init();

      // 检查更新
      await provider.checkUpdate(owner: owner, repo: repo, isManual: isManual);

      // 根据状态显示对话框
      if (provider.status.name == 'available' ||
          provider.status.name == 'error') {
        await showUpdateDialog(context);
      } else if (provider.status.name == 'noUpdate' && showNoUpdateDialog) {
        await showUpdateDialog(context);
      } else {
        debugPrint('无需更新，不显示对话框');
      }
    } catch (e) {
      // 出错时也显示对话框
      await showUpdateDialog(context);
    }
  }
}