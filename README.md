# ze-memo（野火集）- AI智能笔记助手

<div align="center">
  <img src="https://img.shields.io/badge/Flutter-3.10+-02569B?logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart" alt="Dart">
  <img src="https://img.shields.io/badge/DeepSeek-API-FF6B00" alt="DeepSeek">
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey" alt="Platform">
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License">
</div>

## 📝 简介

ze-memo（野火集）是一款基于 Flutter 开发的智能笔记应用，通过集成 DeepSeek AI 大语言模型，实现笔记内容的自动分类和整理。只需输入笔记内容，AI就会智能地将其归类到合适的类别中，让您的笔记管理更加高效和有序。

## ✨ 核心特性

### 🤖 AI智能分类
- **自动识别**: 基于内容智能识别笔记类别
- **自定义类别**: 支持创建新的笔记类别
- **持续学习**: 随着使用频率提升分类准确性

### 📱 本地安全存储
- **JSON格式**: 采用标准JSON格式存储，便于数据迁移
- **按类别组织**: 每个类别一个独立的JSON文件
- **日期分组**: 笔记按日期自动分组，便于回顾
- **完全离线**: 笔记内容本地存储，无需联网即可查看

### 🎨 用户友好界面
- **Material Design 3**: 遵循最新设计规范
- **流畅动画**: 自然的页面切换和交互动画
- **深色模式**: 支持系统主题自动切换
- **响应式设计**: 适配各种屏幕尺寸

### 🔍 强大的管理功能
- **智能搜索**: 全文搜索所有笔记内容
- **多视图浏览**: 按类别、时间线、统计等多种视图
- **数据统计**: 笔记数量、热词分析等统计信息
- **导入导出**: 支持笔记数据的备份和恢复

## 🚀 快速开始

### 环境要求

- Flutter SDK 3.10.0 或更高版本
- Dart SDK 3.0.0 或更高版本
- Android SDK (Android开发)
- Xcode (iOS开发)

### 安装步骤

1. **克隆项目**
   ```bash
   git clone https://github.com/yourusername/ze-memo.git
   cd ze-memo
   ```

2. **安装依赖**
   ```bash
   flutter pub get
   ```

3. **配置API密钥**
   - 访问 [DeepSeek API平台](https://platform.deepseek.com/) 获取API密钥
   - 首次运行应用时，根据提示输入API密钥

4. **配置Gradle (Android开发)**
   - 打开文件 `android/gradle/wrapper/gradle-wrapper.properties`
   - 将 `distributionUrl` 修改为本地Gradle分发路径，例如：
     ```
     distributionUrl=file:///D:/workspace/Gradle/gradle-8.14-all.zip
     ```
   - 请确保路径指向您本地实际的Gradle文件，但是不要提交到远程仓库中。

5. **运行应用**
   ```bash
   flutter run
   ```

### 构建发布版本

```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS (需要macOS)
flutter build ios --release
```

## 📖 使用指南

### 首次使用

1. **启动应用**: 欢迎页面介绍应用功能
2. **配置API**: 输入您的DeepSeek API密钥
3. **开始记录**: 在AI对话页面输入您的第一篇笔记

### 主要功能

#### 📝 记录笔记
1. 打开应用，默认进入AI对话页面
2. 在输入框中输入笔记内容
3. 点击发送按钮
4. AI自动分析并分类保存

#### 📚 浏览笔记
1. 切换到"笔记浏览"标签页
2. 选择查看方式：
   - **按类别**: 左侧选择类别，右侧查看详细内容
   - **按时间**: 按时间顺序查看所有笔记
   - **统计**: 查看笔记统计和热词分析

#### 🔍 搜索笔记
1. 点击搜索按钮
2. 输入关键词
3. 实时搜索并高亮显示结果

#### ⚙️ 设置管理
1. 点击右上角菜单
2. 可以进行的操作：
   - 配置API密钥
   - 清空对话记录
   - 查看统计信息
   - 导入导出数据

## 🏗️ 技术架构

### 项目结构
```
lib/
├── app/                    # 应用主配置
│   ├── app.dart           # 应用入口配置
│   └── theme/             # 主题配置
├── core/                  # 核心工具
│   ├── constants/         # 常量定义
│   └── utils/             # 工具类
├── data/                  # 数据层
│   ├── models/            # 数据模型
│   └── services/          # 服务层
└── presentation/          # 表现层
    ├── providers/         # 状态管理
    ├── pages/             # 页面
    └── widgets/           # 组件
```

### 技术栈

- **框架**: Flutter 3.10+
- **语言**: Dart 3.0+
- **状态管理**: Provider + ChangeNotifier
- **网络请求**: Dio 5.x
- **本地存储**:
  - path_provider (文件路径)
  - shared_preferences (配置存储)
- **AI服务**: DeepSeek API
- **UI组件**: Material Design 3
- **字体**: Google Fonts

### 数据模型

```dart
// 笔记文件
class NoteFile {
  final String id;                          // 文件ID
  final String category;                    // 类别名称
  final String title;                       // 文件标题
  final String description;                 // 类别描述
  final DateTime createdAt;                 // 创建时间
  final DateTime updatedAt;                 // 更新时间
  final Map<String, List<NoteEntry>> entriesByDate; // 按日期分组的条目
}

// 笔记条目
class NoteEntry {
  final String id;                          // 条目ID
  final String content;                     // 内容
  final DateTime timestamp;                 // 时间戳
}

// 分类结果
class ClassificationResult {
  final String categoryId;                  // 类别ID
  final bool isNewCategory;                 // 是否新类别
  final String? newCategoryName;            // 新类别名称
  final String? newDescription;             // 新类别描述
}
```

## 🤝 贡献指南

欢迎贡献代码！请遵循以下步骤：

1. Fork 本项目
2. 创建您的特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交您的更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开一个 Pull Request

### 开发规范

- 遵循 [Dart官方代码规范](https://dart.dev/guides/language/effective-dart/style)
- 使用有意义的提交信息
- 为新功能添加相应的测试
- 更新相关文档

## 🐛 问题反馈

如果您遇到任何问题或有功能建议，请：

1. 查看 [Issues](https://github.com/yourusername/ze-memo/issues) 确认问题未被报告
2. 创建新的Issue，详细描述问题或建议
3. 提供复现步骤（如果是bug）
4. 添加相关标签（bug、enhancement等）

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🙏 致谢

- [Flutter](https://flutter.dev/) - 跨平台移动应用框架
- [DeepSeek](https://www.deepseek.ai/) - AI大语言模型服务
- [Material Design](https://m3.material.io/) - 设计规范

## 🔗 相关链接

- [Flutter官方文档](https://flutter.dev/docs)
- [DeepSeek API文档](https://platform.deepseek.com/api-docs)
- [项目演示视频](https://example.com) (待添加)

---

<div align="center">
  <p>如果这个项目对您有帮助，请给个 ⭐ Star 支持一下！</p>
</div>
