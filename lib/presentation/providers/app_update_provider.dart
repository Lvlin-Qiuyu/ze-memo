import 'package:flutter/foundation.dart';
import '../../core/services/app_update_service.dart';

/// 应用更新状态
enum UpdateStatus {
  idle,         // 空闲
  checking,     // 检查中
  available,    // 有更新
  downloading,  // 下载中
  installing,   // 安装中
  error,        // 错误
  noUpdate,     // 无更新
}

/// 应用更新信息
class UpdateInfo {
  final String version;
  final String title;
  final String description;
  final String downloadUrl;

  UpdateInfo({
    required this.version,
    required this.title,
    required this.description,
    required this.downloadUrl,
  });
}

/// 应用更新 Provider
class AppUpdateProvider extends ChangeNotifier {
  final AppUpdateService _updateService = AppUpdateService();

  UpdateStatus _status = UpdateStatus.idle;
  UpdateInfo? _updateInfo;
  int _downloadProgress = 0;
  String? _errorMessage;

  // Getters
  UpdateStatus get status => _status;
  UpdateInfo? get updateInfo => _updateInfo;
  int get downloadProgress => _downloadProgress;
  String? get errorMessage => _errorMessage;

  /// 初始化
  Future<void> init() async {
    try {
      await _updateService.init();
    } catch (e) {
      _setError(e.toString());
    }
  }

  /// 检查更新
  /// [owner]: Gitee 仓库所有者
  /// [repo]: Gitee 仓库名称
  Future<void> checkUpdate({
    required String owner,
    required String repo,
  }) async {
    _setStatus(UpdateStatus.checking);
    _errorMessage = null;

    try {
      final release = await _updateService.checkUpdate(owner: owner, repo: repo);

      if (release != null) {
        final apkUrl = release.getApkDownloadUrl();
        if (apkUrl != null) {
          _updateInfo = UpdateInfo(
            version: release.tagName,
            title: release.name,
            description: release.body,
            downloadUrl: apkUrl,
          );
          _setStatus(UpdateStatus.available);
        } else {
          _setStatus(UpdateStatus.error);
          _errorMessage = '未找到 APK 下载链接';
        }
      } else {
        _setStatus(UpdateStatus.noUpdate);
      }
    } catch (e) {
      _setError('检查更新失败: $e');
    }
  }

  /// 下载并安装更新
  Future<void> downloadAndInstall() async {
    if (_updateInfo == null || _status != UpdateStatus.available) {
      debugPrint('更新信息为空或状态不正确: status=${_status.name}');
      return;
    }

    debugPrint('开始下载更新: ${_updateInfo!.version}');
    _setStatus(UpdateStatus.downloading);
    _downloadProgress = 0;
    _errorMessage = null;

    try {
      // 生成文件名
      final fileName = 'ze_memo_${_updateInfo!.version}.apk';
      debugPrint('下载文件名: $fileName');
      debugPrint('下载链接: ${_updateInfo!.downloadUrl}');

      // 下载 APK
      final filePath = await _updateService.downloadApk(
        url: _updateInfo!.downloadUrl,
        fileName: fileName,
        onProgress: (progress) {
          _downloadProgress = progress;
          notifyListeners();
          if (progress % 20 == 0) {
            debugPrint('下载进度: $progress%');
          }
        },
      );

      debugPrint('下载完成');
      debugPrint('文件路径: $filePath');

      // 安装 APK
      debugPrint('开始安装 APK');
      _setStatus(UpdateStatus.installing);
      await _updateService.installApk(filePath);

      debugPrint('安装调用完成');
      // 安装成功后，恢复空闲状态
      _setStatus(UpdateStatus.idle);
    } catch (e) {
      debugPrint('下载或安装失败: $e');
      debugPrint('错误类型: ${e.runtimeType}');
      _setError('下载或安装失败: $e');
    }
  }

  /// 重置状态
  void reset() {
    _status = UpdateStatus.idle;
    _updateInfo = null;
    _downloadProgress = 0;
    _errorMessage = null;
    notifyListeners();
  }

  /// 忽略本次更新
  void ignoreUpdate() {
    _setStatus(UpdateStatus.idle);
    _updateInfo = null;
  }

  
  /// 设置状态
  void _setStatus(UpdateStatus status) {
    _status = status;
    notifyListeners();
  }

  /// 设置错误信息
  void _setError(String error) {
    _status = UpdateStatus.error;
    _errorMessage = error;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}