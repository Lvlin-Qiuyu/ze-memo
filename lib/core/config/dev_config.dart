import 'environment_manager.dart';

class DevConfig {
  // 开发环境配置
  static const bool useProxy = false; // 设置为 true 使用代理服务器

  // API 基础 URL - 优先使用环境变量，否则使用默认值
  static String get apiBaseUrl {
    final envBaseUrl = EnvironmentManager.instance.deepseekBaseUrl;
    if (envBaseUrl != null && envBaseUrl.isNotEmpty) {
      return envBaseUrl;
    }
    
    return useProxy
        ? 'http://localhost:8081/api/v1'  // 通过代理服务器
        : 'https://api.deepseek.com/v1';  // 直接请求（需要禁用 CORS）
  }
}