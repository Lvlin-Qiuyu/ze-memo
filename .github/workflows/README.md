# Android 自动构建配置说明

## 配置签名密钥

在 GitHub Actions 中自动构建签名的 APK，需要将签名密钥信息配置到 GitHub Secrets 中。

### 1. 生成签名密钥（如果还没有）

在项目根目录执行：
```bash
cd android/app
keytool -genkey -v -keystore ze-memo.jks -keyalg RSA -keysize 2048 -validity 10000 -alias ze-memo
```

### 2. 将密钥文件转换为 Base64

在 macOS 或 Linux 上：
```bash
base64 -i android/app/ze-memo.jks | pbcopy
```

在 Windows 上（使用 PowerShell）：
```powershell
[System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes("android/app/ze-memo.jks")) | Set-Clipboard
```

### 3. 配置 GitHub Secrets

在 GitHub 仓库中，进入 `Settings` > `Secrets and variables` > `Actions`，添加以下 secrets：

| Secret 名称 | 值 | 说明 |
|-------------|-----|------|
| `KEYSTORE_BASE64` | 上一步复制的 Base64 字符串 | 签名密钥文件的 Base64 编码 |
| `KEYSTORE_PASSWORD` | 你的密钥库密码 | 创建密钥时设置的密码 |
| `KEY_ALIAS` | `ze-memo` | 密钥别名 |
| `KEY_PASSWORD` | 你的密钥密码 | 密钥的密码（通常与密钥库密码相同） |

### 4. 构建触发条件

- 推送到 `main` 或 `develop` 分支
- 创建标签（格式为 `v*`，如 `v1.0.0`）
- 针对 `main` 分支的 Pull Request

### 5. 下载构建产物

构建完成后，可以在 GitHub Actions 页面下载生成的 APK 文件，或者在 Releases 页面查看由标签触发的发布版本。

### 6. 本地测试构建

在提交到 GitHub 前，可以在本地测试构建：

```bash
flutter clean
flutter pub get
flutter build apk --release
```

### 注意事项

- 确保 Android SDK 版本兼容性
- 不要将密钥文件提交到版本控制系统
- 定期更新签名密钥的有效期（当前设置为 10000 天）