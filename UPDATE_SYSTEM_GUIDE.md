# 应用内更新系统使用指南

本文档介绍如何配置和使用已实现的 Flutter 应用内更新系统。

## 系统概述

该更新系统使用 Gitee Releases 作为更新源，支持自动检查版本、下载 APK 并提示用户安装。

## 核心功能

1. **自动检查更新**: 应用启动时自动检查 Gitee 仓库的最新 Release
2. **版本比较**: 智能比较版本号（支持带 v 前缀的版本号）
3. **下载进度显示**: 实时显示下载进度
4. **安装提示**: 下载完成后自动调用系统安装程序
5. **错误处理**: 完善的错误处理和用户提示

## 配置步骤

### 1. 配置 Gitee 仓库信息

编辑 `lib/core/config/update_config.dart` 文件：

```dart
class UpdateConfig {
  // Gitee 仓库信息 - 请根据实际情况修改
  static const String giteeOwner = 'your-gitee-username'; // 替换为你的Gitee用户名
  static const String giteeRepo = 'ze-memo'; // 替换为你的仓库名

  // 可选：设置检查更新的频率（小时）
  static const int checkIntervalHours = 24;

  // 可选：是否在DEBUG模式下也检查更新
  static const bool checkInDebugMode = false;
}
```

### 2. 确保 Android 配置正确

以下配置已完成，请确认无误：

#### AndroidManifest.xml
- ✅ `REQUEST_INSTALL_PACKAGES` 权限已添加
- ✅ `FileProvider` 已配置

#### provider_paths.xml
- ✅ 文件路径配置已完成

### 3. 发布新版本到 Gitee

1. 在 Gitee 仓库中创建新的 Release
2. 版本号格式建议：`v1.0.7` 或 `1.0.7`
3. 在 Release 的 Assets 部分上传 APK 文件
4. 填写 Release 说明（这些内容会显示在更新对话框中）

## 系统架构

### 文件结构

```
lib/
├── core/
│   ├── services/
│   │   └── app_update_service.dart      # 更新服务核心逻辑
│   ├── config/
│   │   └── update_config.dart           # 更新配置
│   └── utils/
│       └── app_update_helper.dart       # 更新帮助类
├── presentation/
│   ├── providers/
│   │   └── app_update_provider.dart     # 状态管理
│   └── widgets/
│       └── update_dialog_widget.dart    # 更新对话框 UI
└── app/
    └── app.dart                         # 应用入口（已集成）
```

### 核心类说明

#### 1. AppUpdateService
负责与 Gitee API 交互，包括：
- 获取最新 Release 信息
- 下载 APK 文件
- 调用系统安装程序
- 版本号比较

#### 2. AppUpdateProvider
使用 Provider 模式管理更新状态：
- 检查更新状态
- 下载进度
- 错误信息

#### 3. UpdateDialogWidget
更新对话框 UI，显示：
- 检查中/下载中/安装中的不同状态
- 版本信息和更新内容
- 下载进度条
- 操作按钮

## 手动触发更新检查

如果需要在其他地方手动触发更新检查：

```dart
import 'package:provider/provider.dart';
import '../core/utils/app_update_helper.dart';

// 方法1：使用帮助类（会显示对话框）
await AppUpdateHelper.checkAndShowUpdate(
  context,
  owner: 'your-gitee-username',
  repo: 'your-repo-name',
);

// 方法2：直接使用 Provider
final provider = Provider.of<AppUpdateProvider>(context, listen: false);
await provider.checkUpdate(
  owner: 'your-gitee-username',
  repo: 'your-repo-name',
);
```

## 注意事项

1. **网络权限**: 确保应用有网络访问权限
2. **存储权限**: 在 Android 11+ 设备上可能需要用户授权
3. **下载目录**: APK 文件下载到应用专用的外部存储目录
4. **签名一致性**: 新版本必须使用与旧版本相同的签名文件
5. **版本号规则**: 版本号必须递增，建议使用语义化版本号

## 测试建议

1. 创建一个测试 Release
2. 确保版本号大于当前版本
3. 上传测试 APK
4. 安装当前版本的应用
5. 启动应用验证更新功能

## 故障排除

### 更新检查失败
- 检查网络连接
- 确认 Gitee 仓库信息是否正确
- 查看控制台错误日志

### 下载失败
- 检查存储空间是否充足
- 确认 APK 文件是否存在于 Release Assets 中

### 安装失败
- 确认已开启"未知来源"安装权限
- 检查 APK 签名是否一致
- 确认版本号是否正确递增

## 扩展功能建议

1. **增量更新**: 支持 patch 文件的增量更新
2. **强制更新**: 对于重要更新，可以实现强制更新功能
3. **更新历史**: 显示最近的更新历史
4. **静默更新**: 在 WiFi 环境下自动下载更新
5. **更新时间设置**: 允许用户设置检查更新的时间