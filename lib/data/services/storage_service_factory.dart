import 'package:flutter/foundation.dart' show kIsWeb;
import 'storage_interface.dart';
import 'storage_service.dart';
import 'web_storage_service.dart';

/// 存储服务工厂
class StorageServiceFactory {
  static IStorageService? _instance;

  static IStorageService getInstance() {
    if (_instance == null) {
      if (kIsWeb) {
        _instance = WebStorageService();
      } else {
        _instance = StorageService();
      }
    }
    return _instance!;
  }

  // 重置实例（用于测试）
  static void resetInstance() {
    _instance = null;
  }
}