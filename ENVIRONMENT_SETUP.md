# 快速参考：环境变量配置

## 🚀 快速开始

### 1. 本地开发环境设置

#### Windows用户
```bash
# 运行设置脚本
setup_env.bat
```

#### Linux/macOS用户
```bash
# 运行设置脚本
chmod +x setup_env.sh
./setup_env.sh
```

#### 手动设置
```bash
# 1. 复制模板文件
cp .env.example .env

# 2. 编辑.env文件，填入您的API密钥
# DEEPSEEK_API_KEY=sk-your-api-key-here

# 3. 开始开发
flutter run
```

### 2. CI/CD环境设置

在GitHub仓库中设置以下Secrets：
- `DEEPSEEK_API_KEY`: 您的DeepSeek API密钥
- `KEYSTORE_BASE64`: 签名文件Base64编码
- `KEYSTORE_PASSWORD`: 签名文件密码
- `KEY_ALIAS`: 签名别名
- `KEY_PASSWORD`: 签名密钥密码

## 📁 重要文件

| 文件 | 用途 | 是否提交到版本控制 |
|------|------|-------------------|
| `.env.example` | 环境变量模板 | ✅ |
| `.env` | 本地环境变量（敏感） | ❌ |
| `lib/core/config/environment_manager.dart` | 环境变量管理器 | ✅ |
| `.github/workflows/build-android.yml` | CI/CD工作流 | ✅ |
| `docs/environment-variables-guide.md` | 完整配置文档 | ✅ |

## 🔧 构建命令

### 本地构建
```bash
# 开发调试
flutter run

# 调试构建
flutter build apk --debug

# 发布构建（自动使用.env配置）
flutter build apk --release
```

### CI/CD构建
```bash
# 推送代码到main分支或创建标签时自动构建
# 无需手动执行，使用GitHub Secrets中的配置
```

## ⚠️ 安全提醒

1. **永远不要** 将真实的API密钥提交到版本控制系统
2. **始终使用** `.env` 文件存储本地敏感信息
3. **定期更新** API密钥（建议每3-6个月）
4. **监控API** 使用情况，发现异常立即处理

## 🔍 故障排除

### 常见问题
- **API密钥未生效**: 检查`.env`文件格式，确保变量名正确
- **构建失败**: 运行 `flutter clean && flutter pub get`
- **CI/CD失败**: 检查GitHub Secrets配置是否正确

### 调试方法
```dart
// 在代码中添加调试信息
print('API Key loaded: ${EnvironmentManager.instance.deepseekApiKey?.isNotEmpty}');
print('Environment: ${EnvironmentManager.instance.environment}');
```

## 📞 获取帮助

- 查看完整文档：[docs/environment-variables-guide.md](docs/environment-variables-guide.md)
- 检查 `.env.example` 文件了解可用变量
- 运行 `setup_env.bat` 或 `setup_env.sh` 脚本获得引导式设置

---
**记住**：API密钥是敏感信息，请妥善保管！