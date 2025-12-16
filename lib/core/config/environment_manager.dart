import 'dart:io';

/// 环境变量管理类
/// 支持从本地.env文件和运行时环境变量读取配置
class EnvironmentManager {
  static EnvironmentManager? _instance;
  static EnvironmentManager get instance => _instance ??= EnvironmentManager._();

  EnvironmentManager._();

  final Map<String, String> _envVars = {};

  /// 初始化环境变量管理器
  Future<void> initialize() async {
    await _loadEnvironmentVariables();
  }

  /// 从本地.env文件和系统环境变量加载环境变量
  Future<void> _loadEnvironmentVariables() async {
    try {
      // 1. 尝试从本地.env文件加载
      await _loadFromEnvFile();

      // 2. 尝试从系统环境变量加载 (适用于CI/CD环境)
      await _loadFromSystemEnv();
    } catch (e) {
      print('警告：环境变量加载失败: $e');
    }
  }

  /// 从本地.env文件加载环境变量
  Future<void> _loadFromEnvFile() async {
    try {
      final envFile = File('.env');
      if (await envFile.exists()) {
        final lines = await envFile.readAsLines();
        for (final line in lines) {
          _parseEnvLine(line);
        }
        print('从本地.env文件加载环境变量成功');
      }
    } catch (e) {
      print('加载.env文件失败: $e');
    }
  }

  /// 从系统环境变量加载 (适用于CI/CD环境)
  Future<void> _loadFromSystemEnv() async {
    try {
      // 在Flutter web或移动端，我们可以通过以下方式获取环境变量：
      // 1. 通过编译时常量传递 (flutter build --dart-define=KEY=VALUE)
      // 2. 通过Platform.environment (仅适用于Flutter桌面端)
      
      // 检查编译时常量 (通过 --dart-define 传递)
      final dartDefineKey = const String.fromEnvironment('DEEPSEEK_API_KEY');
      if (dartDefineKey.isNotEmpty && dartDefineKey != 'null') {
        _envVars['DEEPSEEK_API_KEY'] = dartDefineKey;
        print('从编译时常量加载DEEPSEEK_API_KEY成功');
        return;
      }

      // 检查其他环境变量
      for (final key in ['ENVIRONMENT', 'DEEPSEEK_BASE_URL']) {
        final value = String.fromEnvironment(key);
        if (value.isNotEmpty && value != 'null') {
          _envVars[key] = value;
        }
      }
    } catch (e) {
      print('从系统环境变量加载失败: $e');
    }
  }

  /// 解析.env文件的每一行
  void _parseEnvLine(String line) {
    final trimmedLine = line.trim();
    
    // 跳过空行和注释行
    if (trimmedLine.isEmpty || trimmedLine.startsWith('#')) {
      return;
    }

    // 解析 KEY=VALUE 格式
    final equalsIndex = trimmedLine.indexOf('=');
    if (equalsIndex == -1) return;

    final key = trimmedLine.substring(0, equalsIndex).trim();
    var value = trimmedLine.substring(equalsIndex + 1).trim();

    // 移除引号
    if ((value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"))) {
      value = value.substring(1, value.length - 1);
    }

    _envVars[key] = value;
  }

  /// 获取环境变量的通用方法
  String? _getEnvVar(String key) {
    // 优先级：编译时常量 > .env文件
    String? value;

    // 1. 尝试从编译时常量获取 (通过flutter build --dart-define)
    value = String.fromEnvironment(key);
    if (value.isNotEmpty && value != 'null') {
      return value;
    }

    // 2. 从已加载的.env文件环境变量中获取
    value = _envVars[key];

    return value;
  }

  /// 获取DeepSeek API密钥
  String? get deepseekApiKey => _getEnvVar('DEEPSEEK_API_KEY');

  /// 获取环境名称
  String? get environment => _getEnvVar('ENVIRONMENT');

  /// 获取DeepSeek API基础URL
  String? get deepseekBaseUrl => _getEnvVar('DEEPSEEK_BASE_URL');

  /// 检查是否为生产环境
  bool get isProduction => 
    (environment?.toLowerCase() == 'production') || 
    (environment?.toLowerCase() == 'prod');

  /// 检查是否为开发环境
  bool get isDevelopment => 
    environment?.toLowerCase() == 'development' || 
    environment?.toLowerCase() == 'dev';

  /// 检查是否为测试环境
  bool get isTesting => 
    environment?.toLowerCase() == 'testing' || 
    environment?.toLowerCase() == 'test';

  /// 获取指定的环境变量值
  String? operator [](String key) => _getEnvVar(key);

  /// 检查环境变量是否存在
  bool hasKey(String key) => _getEnvVar(key) != null;

  /// 获取所有环境变量 (用于调试)
  Map<String, String> get allVariables => Map.unmodifiable(_envVars);
}