# 导入导出功能实现文档

## 功能概述

为野火集笔记应用实现了完整的笔记导入导出功能，允许用户：
- 将所有笔记导出为 JSON 格式的备份文件
- 从 JSON 备份文件导入笔记到应用中

## 实现的文件

### 1. 新增文件

#### `lib/core/services/import_export_service.dart`
导入导出服务的核心实现，包含：
- `exportNotesToFile()` - 导出笔记到本地文件
- `importNotesFromFile()` - 从本地文件导入笔记
- `_validateImportData()` - 验证导入数据的格式
- 权限处理（支持 Android 11+ 的存储权限）

#### `test/import_export_test.dart`
单元测试文件，测试：
- NoteFile 的序列化/反序列化
- 导入数据格式的验证

### 2. 修改的文件

#### `pubspec.yaml`
添加了以下依赖：
- `file_picker: ^8.0.0+1` - 文件选择器
- `permission_handler: ^11.0.1` - 权限管理

#### `lib/presentation/pages/notes_page.dart`
- 导入 `ImportExportService`
- 更新了 `_exportNotes()` 方法，实现导出功能
- 更新了 `_importNotes()` 方法，实现导入功能

#### `lib/data/services/storage_service.dart`
- 添加了 `path_provider` 导入

#### `android/app/src/main/AndroidManifest.xml`
添加了存储权限：
- `WRITE_EXTERNAL_STORAGE`
- `READ_EXTERNAL_STORAGE`
- `MANAGE_EXTERNAL_STORAGE` (Android 11+)

#### `ios/Runner/Info.plist`
添加了 iOS 文件访问权限描述：
- `NSDocumentsFolderUsageDescription`
- `NSPhotoLibraryAddUsageDescription`

## 功能特性

### 导出功能
- 自动生成带时间戳的文件名（格式：`ze_memo_backup_YYYYMMDD_HHMM.json`）
- 导出数据包含：
  - 导出时间
  - 版本信息
  - 文件总数
  - 笔记总数
  - 所有笔记文件（JSON 格式）
- 支持用户选择保存位置
- 格式化的 JSON 输出，便于阅读

### 导入功能
- 支持选择 JSON 格式的备份文件
- 自动验证文件格式
- 显示导入摘要对话框，包含：
  - 备份文件名
  - 导出时间
  - 包含的类别数量
  - 笔记总数
- 导入时不会覆盖现有数据，而是追加到现有笔记中

### 权限处理
- Android：支持旧版存储权限和 Android 11+ 的管理外部存储权限
- iOS：添加了必要的文件访问权限描述
- 自动请求权限，并提供友好的错误提示

## 使用方法

### 导出笔记
1. 在笔记浏览页面点击右上角菜单
2. 选择"导出笔记"
3. 在弹出的文件保存对话框中选择保存位置
4. 点击保存

### 导入笔记
1. 在笔记浏览页面点击右上角菜单
2. 选择"导入笔记"
3. 在文件选择对话框中选择备份文件（.json）
4. 查看导入摘要
5. 点击"导入"确认

## 注意事项

1. **备份文件格式**：导出的是 JSON 格式文件，包含了所有笔记的完整信息

2. **导入规则**：导入是追加模式，不会删除或覆盖现有的笔记

3. **权限要求**：
   - Android 需要存储权限才能访问文件系统
   - iOS 需要文档文件夹访问权限

4. **兼容性**：
   - 支持 Android 5.0+ 和 iOS 11.0+
   - 导出的备份文件在不同平台间兼容

## 技术细节

### JSON 数据结构
```json
{
  "exportDate": "2025-12-15T10:30:00.000Z",
  "version": "1.0",
  "totalFiles": 3,
  "totalEntries": 50,
  "noteFiles": [
    {
      "id": "uuid",
      "category": "类别名",
      "title": "标题",
      "description": "描述",
      "createdAt": "2025-12-15T10:00:00.000Z",
      "updatedAt": "2025-12-15T10:30:00.000Z",
      "entries": [
        {
          "id": "uuid",
          "content": "笔记内容",
          "timestamp": "2025-12-15T10:30:00.000Z"
        }
      ]
    }
  ]
}
```

### 错误处理
- 文件读写错误处理
- 权限拒绝处理
- 无效文件格式处理
- 用户友好的错误提示