class DevConfig {
  // 开发环境配置
  static const bool useProxy = false; // 设置为 true 使用代理服务器

  // API 基础 URL
  static const String apiBaseUrl = useProxy
      ? 'http://localhost:8081/api/v1'  // 通过代理服务器
      : 'https://api.deepseek.com/v1';  // 直接请求（需要禁用 CORS）
}