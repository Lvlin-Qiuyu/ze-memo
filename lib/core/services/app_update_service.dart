import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart' as pp;
import 'package:open_filex/open_filex.dart';

/// Gitee Release 信息模型
class GiteeRelease {
  final String tagName;
  final String name;
  final String body;
  final List<GiteeAsset> assets;

  GiteeRelease({
    required this.tagName,
    required this.name,
    required this.body,
    required this.assets,
  });

  factory GiteeRelease.fromJson(Map<String, dynamic> json) {
    final assetsList = (json['assets'] as List? ?? [])
        .map((e) => GiteeAsset.fromJson(e as Map<String, dynamic>))
        .toList();

    return GiteeRelease(
      tagName: json['tag_name'] as String? ?? '',
      name: json['name'] as String? ?? '',
      body: json['body'] as String? ?? '',
      assets: assetsList,
    );
  }

  /// 获取 APK 下载链接
  String? getApkDownloadUrl() {
    for (final asset in assets) {
      if (asset.name.endsWith('.apk')) {
        return asset.downloadUrl;
      }
    }
    return null;
  }
}

/// Gitee Release 资源模型
class GiteeAsset {
  final String name;
  final String downloadUrl;

  GiteeAsset({required this.name, required this.downloadUrl});

  factory GiteeAsset.fromJson(Map<String, dynamic> json) {
    return GiteeAsset(
      name: json['name'] as String? ?? '',
      downloadUrl: json['browser_download_url'] as String? ?? '',
    );
  }
}

/// 应用更新服务
class AppUpdateService {
  static const String _giteeApiUrl = 'https://gitee.com/api/v5/repos';

  late final Dio _dio;
  String? _currentVersion;

  AppUpdateService() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    // 添加请求拦截器用于进度跟踪
    _dio.interceptors.add(
      LogInterceptor(requestBody: false, responseBody: false),
    );
  }

  /// 初始化服务，获取当前版本信息
  Future<void> init() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _currentVersion = packageInfo.version;
    } catch (e) {
      throw Exception('获取应用版本信息失败: $e');
    }
  }

  /// 检查更新
  /// [owner]: Gitee 仓库所有者
  /// [repo]: Gitee 仓库名称
  /// 返回 [GiteeRelease] 如果有更新，否则返回 null
  Future<GiteeRelease?> checkUpdate({
    required String owner,
    required String repo,
  }) async {
    try {
      // 确保已初始化
      if (_currentVersion == null) {
        await init();
      }

      debugPrint('当前版本: $_currentVersion');

      // 获取最新 Release 信息
      final url = '$_giteeApiUrl/$owner/$repo/releases/latest';
      debugPrint('请求 URL: $url');

      final response = await _dio.get(
        url,
        options: Options(headers: {'Accept': 'application/json'}),
      );
      if (response.statusCode == 200) {
        final release = GiteeRelease.fromJson(response.data);
        debugPrint('最新版本: ${release.tagName}');
        debugPrint('Assets 数量: ${release.assets.length}');

        for (var asset in release.assets) {
          debugPrint('Asset: ${asset.name}');
        }

        // 比较版本号
        if (_isNewerVersion(release.tagName)) {
          debugPrint('发现新版本！${_currentVersion} -> ${release.tagName}');
          return release;
        } else {
          debugPrint('当前已是最新版本');
        }
      }

      return null;
    } catch (e) {
      debugPrint('请求失败: $e');
      debugPrint('错误类型: ${e.runtimeType}');
      throw Exception('检查更新失败: $e');
    }
  }

  /// 下载 APK
  /// [url]: 下载链接
  /// [fileName]: 文件名
  /// [onProgress]: 下载进度回调 (0-100)
  /// [cancelToken]: 取消请求的Token
  /// 返回下载后的文件路径
  Future<String> downloadApk({
    required String url,
    required String fileName,
    required Function(int progress) onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      // Android 10+ 适配：使用应用私有缓存目录，不需要敏感权限
      Directory? directory;
      if (Platform.isAndroid) {
        // 使用临时目录 (internal cache)，provider_paths 已配置 <cache-path>
        directory = await pp.getTemporaryDirectory();
      } else {
        directory = await pp.getApplicationSupportDirectory();
      }

      if (directory == null) {
        throw Exception('无法获取存储目录');
      }

      // 创建下载目录
      final downloadDir = Directory('${directory.path}/updates');
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      final filePath = '${downloadDir.path}/$fileName';
      final file = File(filePath);

      // 如果文件已存在，先删除
      if (await file.exists()) {
        await file.delete();
      }

      // 开始下载
      await _dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final progress = ((received / total) * 100).round();
            onProgress(progress);
          }
        },
        cancelToken: cancelToken,
        options: Options(receiveTimeout: const Duration(minutes: 10)),
      );

      return filePath;
    } catch (e) {
      if (CancelToken.isCancel(e as DioException)) {
        throw Exception('下载已取消');
      }
      throw Exception('下载失败: $e');
    }
  }

  /// 安装 APK
  /// [filePath]: APK 文件路径
  Future<void> installApk(String filePath) async {
    try {
      final result = await OpenFilex.open(filePath);

      if (result.type != ResultType.done) {
        throw Exception('启动安装失败: ${result.message}');
      }
    } catch (e) {
      throw Exception('安装失败: $e');
    }
  }

  /// 比较版本号
  /// [newVersion]: 新版本号（可能包含 v 前缀）
  /// 返回 true 如果新版本更新
  bool _isNewerVersion(String newVersion) {
    if (_currentVersion == null) return false;

    // 移除 v 前缀
    String cleanNewVersion = newVersion.toLowerCase().replaceAll(
      RegExp(r'^v'),
      '',
    );
    String cleanCurrentVersion = _currentVersion!.toLowerCase().replaceAll(
      RegExp(r'^v'),
      '',
    );

    // 分割版本号
    final newParts = cleanNewVersion
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();
    final currentParts = cleanCurrentVersion
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();

    // 补齐版本号长度
    final maxLength = newParts.length > currentParts.length
        ? newParts.length
        : currentParts.length;
    while (newParts.length < maxLength) newParts.add(0);
    while (currentParts.length < maxLength) currentParts.add(0);

    // 逐位比较
    for (int i = 0; i < maxLength; i++) {
      if (newParts[i] > currentParts[i]) {
        return true;
      } else if (newParts[i] < currentParts[i]) {
        return false;
      }
    }

    return false;
  }

  /// 获取当前版本号
  String? get currentVersion => _currentVersion;
}
