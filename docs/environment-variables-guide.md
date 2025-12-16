# 环境变量管理配置指南

## 概述

本文档详细说明了ze-memo项目中环境变量的配置、使用和安全管理方法。主要解决DeepSeek API密钥的硬编码问题，实现本地开发和CI/CD环境的安全配置管理。

## 文件结构

```
ze-memo/
├── .env.example           # 环境变量模板文件
├── .env                   # 本地环境变量文件（已添加到.gitignore）
├── lib/core/config/
│   └── environment_manager.dart  # 环境变量管理器
└── .github/workflows/
    └── build-android.yml  # CI/CD工作流配置
```

## 环境变量配置

### 本地开发环境

1. **复制环境变量模板**
   ```bash
   cp .env.example .env
   ```

2. **配置本地环境变量**
   编辑 `.env` 文件，填入您的DeepSeek API密钥：
   ```env
   DEEPSEEK_API_KEY=sk-your-actual-api-key-here
   ENVIRONMENT=development
   ```

3. **获取DeepSeek API密钥**
   - 访问 [DeepSeek API平台](https://platform.deepseek.com/)
   - 注册/登录账户
   - 在API管理页面创建新的API密钥
   - 将密钥复制到 `.env` 文件中

### CI/CD环境（GitHub Actions）

1. **设置GitHub Secrets**
   
   在GitHub仓库中设置以下Secrets：
   - `DEEPSEEK_API_KEY`: 您的DeepSeek API密钥
   - `KEYSTORE_BASE64`: 签名文件的Base64编码
   - `KEYSTORE_PASSWORD`: 签名文件密码
   - `KEY_ALIAS`: 签名别名
   - `KEY_PASSWORD`: 签名密钥密码

2. **配置步骤**
   - 进入仓库Settings > Secrets and variables > Actions
   - 点击"New repository secret"
   - 依次添加上述所有Secrets

## 环境变量加载机制

### 加载优先级

1. **运行时环境变量**（最高优先级）
   - CI/CD环境变量
   - 系统环境变量

2. **编译时常量**
   - 通过 `flutter build --dart-define=KEY=VALUE` 传递

3. **本地.env文件**
   - 本地开发环境变量文件

4. **默认值**（最低优先级）
   - 代码中的硬编码默认值

### 加载流程

```dart
// 应用程序启动时初始化
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvironmentManager.instance.initialize();
  runApp(const App());
}
```

## 使用示例

### 在代码中获取环境变量

```dart
import 'package:ze_memo/core/config/environment_manager.dart';

// 获取DeepSeek API密钥
final apiKey = EnvironmentManager.instance.deepseekApiKey;

// 获取环境名称
final environment = EnvironmentManager.instance.environment;

// 检查环境类型
if (EnvironmentManager.instance.isProduction) {
  // 生产环境逻辑
}
```

### 在构建中使用环境变量

#### 本地构建
```bash
# 开发构建
flutter run

# 调试构建
flutter build apk --debug

# 发布构建（自动使用.env文件中的配置）
flutter build apk --release
```

#### CI/CD构建
```bash
# 自动使用GitHub Secrets中的配置
flutter build apk --release --dart-define=DEEPSEEK_API_KEY=${{ secrets.DEEPSEEK_API_KEY }}
```

## 安全措施

### 文件安全

1. **.gitignore配置**
   ```
   # Environment variables and sensitive configuration
   .env
   .env.local
   .env.*.local
   ```

2. **敏感信息保护**
   - `.env` 文件已添加到 `.gitignore`
   - 永远不要将真实的API密钥提交到版本控制系统
   - 使用 `.env.example` 作为模板

### 密钥轮换

1. **定期更新API密钥**
   - 建议每3-6个月更新一次DeepSeek API密钥
   - 在GitHub Secrets中更新 `DEEPSEEK_API_KEY`
   - 更新本地 `.env` 文件

2. **密钥泄露应急处理**
   - 如果怀疑密钥泄露，立即在DeepSeek控制台删除该密钥
   - 创建新的API密钥
   - 更新所有环境中的配置

### 环境隔离

1. **开发/测试/生产环境分离**
   - 为不同环境使用不同的API密钥
   - 设置不同的 `ENVIRONMENT` 变量值
   - 在代码中根据环境调整行为

## 故障排除

### 常见问题

1. **API密钥未加载**
   ```bash
   # 检查.env文件是否存在
   ls -la .env
   
   # 检查文件内容
   cat .env
   ```

2. **构建失败**
   ```bash
   # 清理构建缓存
   flutter clean
   flutter pub get
   
   # 重新构建
   flutter build apk --release
   ```

3. **CI/CD环境变量未设置**
   - 检查GitHub仓库的Secrets配置
   - 确认Secrets名称正确
   - 验证工作流权限

### 调试方法

1. **启用详细日志**
   ```dart
   // 在应用中添加调试信息
   print('Environment variables: ${EnvironmentManager.instance.allVariables}');
   ```

2. **检查构建日志**
   - 在GitHub Actions中查看构建日志
   - 确认环境变量是否正确传递

## 最佳实践

1. **密钥管理**
   - 使用强密码和随机生成的API密钥
   - 定期轮换密钥
   - 监控API使用情况

2. **配置管理**
   - 保持配置文件的版本控制，但排除敏感信息
   - 使用环境特定的配置文件
   - 文档化所有配置选项

3. **安全性**
   - 最小权限原则
   - 定期安全审计
   - 监控异常活动

## 维护和更新

### 添加新的环境变量

1. 在 `.env.example` 中添加新变量
2. 在 `EnvironmentManager` 类中添加对应的getter
3. 更新文档
4. 测试新变量的加载

### 升级指南

1. **从硬编码迁移到环境变量**
   ```dart
   // 旧方式（硬编码）
   static const String _defaultApiKey = 'sk-...';
   
   // 新方式（环境变量）
   final apiKey = EnvironmentManager.instance.deepseekApiKey;
   ```

2. **验证迁移**
   - 测试本地环境
   - 测试CI/CD环境
   - 确认功能正常工作

## 联系和支持

如有疑问或需要帮助，请：
1. 查看本文档的故障排除部分
2. 检查项目的Issues页面
3. 联系开发团队

---

**重要提醒**：请确保妥善保管您的API密钥，不要与他人分享或在公开场所展示。