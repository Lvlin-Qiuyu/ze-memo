import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/app_update_service.dart';
import '../../core/config/update_config.dart';

/// 应用更新状态
enum UpdateStatus {
  idle, // 空闲
  checking, // 检查中
  available, // 有更新
  downloading, // 下载中
  installing, // 安装中
  error, // 错误
  noUpdate, // 无更新
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
  CancelToken? _cancelToken;

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
  /// [isManual]: 是否手动检查
  Future<void> checkUpdate({
    required String owner,
    required String repo,
    bool isManual = false,
  }) async {
    // 非手动检查且不是 Android 平台，直接忽略（除非 Web/iOS 也有相应逻辑）
    if (!kIsWeb && !Platform.isAndroid && !isManual) {
      return;
    }

    _setStatus(UpdateStatus.checking);
    _errorMessage = null;

    try {
      // 如果不是手动检查，检查是否需跳过
      if (!isManual) {
        final prefs = await SharedPreferences.getInstance();

        // 1. 检查是否跳过此版本
        // 实际上需要在获取到最新版本后才能判断，所以这里先检查时间

        // 2. 检查时间间隔
        final lastCheckTime = prefs.getInt('last_check_time') ?? 0;
        final currentTime = DateTime.now().millisecondsSinceEpoch;
        final intervalMillis = UpdateConfig.checkIntervalHours * 60 * 60 * 1000;

        if (currentTime - lastCheckTime < intervalMillis) {
          debugPrint('距离上次检查未超过 ${UpdateConfig.checkIntervalHours} 小时，跳过自动检查');
          _setStatus(UpdateStatus.idle);
          return;
        }
      }

      final release = await _updateService.checkUpdate(
        owner: owner,
        repo: repo,
      );

      if (release != null) {
        // 检查是否在跳过列表中
        if (!isManual) {
          final prefs = await SharedPreferences.getInstance();
          final skippedVersion = prefs.getString('skipped_version');

          if (skippedVersion == release.tagName) {
            debugPrint('用户已选择跳过版本 ${release.tagName}，不提示更新');
            _setStatus(UpdateStatus.idle);
            return;
          }
        }

        // 更新最后检查时间
        if (!isManual) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt(
            'last_check_time',
            DateTime.now().millisecondsSinceEpoch,
          );
        }

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
        // 更新最后检查时间（即使没有更新也记录）
        if (!isManual) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt(
            'last_check_time',
            DateTime.now().millisecondsSinceEpoch,
          );
        }
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
    _cancelToken = CancelToken();

    try {
      // 生成文件名
      final fileName = 'zememo_${_updateInfo!.version}.apk';
      debugPrint('下载文件名: $fileName');
      debugPrint('下载链接: ${_updateInfo!.downloadUrl}');

      // 下载 APK
      final filePath = await _updateService.downloadApk(
        url: _updateInfo!.downloadUrl,
        fileName: fileName,
        onProgress: (progress) {
          if (_status == UpdateStatus.downloading) {
            _downloadProgress = progress;
            notifyListeners();
          }
        },
        cancelToken: _cancelToken,
      );

      debugPrint('下载完成');
      debugPrint('文件路径: $filePath');

      // 注意：这里需要检查是否已经被取消，虽然后面catch会捕获cancel
      if (_cancelToken?.isCancelled ?? false) {
        return;
      }

      // 安装 APK
      debugPrint('开始安装 APK');
      _setStatus(UpdateStatus.installing);
      await _updateService.installApk(filePath);

      debugPrint('安装调用完成');
      // 注意：安装调用完成后，用户可能取消安装，也可能安装成功重启
      // 这里保持 installing 状态或者 idle 状态是个选择
      // 建议改为 idle 以允许用户再次操作（如果安装界面被关闭）
      // 或者在 UI 层监听生命周期
      _setStatus(UpdateStatus.idle);
    } catch (e) {
      if (CancelToken.isCancel(e as DioException)) {
        debugPrint('下载任务已取消');
        _setStatus(UpdateStatus.idle);
      } else {
        debugPrint('下载或安装失败: $e');
        debugPrint('错误类型: ${e.runtimeType}');
        _setError('下载或安装失败: $e');
      }
    } finally {
      _cancelToken = null;
    }
  }

  /// 取消下载
  void cancelDownload() {
    if (_status == UpdateStatus.downloading && _cancelToken != null) {
      _cancelToken!.cancel('用户手动取消');
      _setStatus(UpdateStatus.idle);
    }
  }

  /// 重置状态
  void reset() {
    _status = UpdateStatus.idle;
    _updateInfo = null;
    _downloadProgress = 0;
    _errorMessage = null;
    _cancelToken = null;
    notifyListeners();
  }

  /// 忽略本次更新（下次还会提示，遵循时间间隔）
  Future<void> remindLater() async {
    _setStatus(UpdateStatus.idle);
    // 更新检查时间到当前，这样根据间隔配置，短期内不会再检查
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      'last_check_time',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// 跳过此版本（永久不再提示此版本）
  Future<void> skipVersion() async {
    if (_updateInfo != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('skipped_version', _updateInfo!.version);
    }
    _setStatus(UpdateStatus.idle);
  }

  // 兼容旧方法，等同于 reset
  void ignoreUpdate() {
    remindLater();
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
    _cancelToken?.cancel();
    super.dispose();
  }
}
