# 导出路径更新说明

## 更改内容

导出功能已更新，现在默认将文件保存到系统的**下载目录**，而不是应用内部目录。

## 各平台的下载目录位置

### Android
- **Android 11及以上版本**：`/storage/emulated/0/Android/data/com.lvlin.ze_memo/files/Downloads`
  - 由于 Android 11+ 的分区存储限制，应用只能在外部存储的应用特定目录下创建文件夹
  - 用户可以通过文件管理器访问该路径

- **Android 10及更早版本**：`/storage/emulated/0/Download`
  - 可以直接访问系统下载目录

### iOS
- 路径：应用文档目录下的 `Downloads` 文件夹
- 可以通过 "文件" App > "我的iPhone/我的iPad" > "野火集" > "Downloads" 访问

### Windows
- 路径：`C:\Users\[用户名]\Downloads`
- 可以通过文件资源管理器直接访问

### macOS
- 路径：`/Users/[用户名]/Downloads`
- 可以通过 Finder 直接访问

### Linux
- 路径：`/home/[用户名]/Downloads`
- 可以通过文件管理器直接访问

## 功能特点

1. **自动创建目录**：如果下载目录不存在，系统会自动创建
2. **权限处理**：
   - Android 自动请求必要的存储权限
   - 不需要用户手动选择保存位置
3. **分享功能**：导出成功后，可以通过 SnackBar 的"分享"按钮分享文件
4. **回退机制**：如果无法访问系统下载目录，会回退到应用文档目录下的 Downloads 文件夹

## 使用说明

1. 点击"导出笔记"
2. 系统自动将文件保存到下载目录
3. 显示成功消息，包含文件完整路径
4. 可选择通过"分享"按钮将文件分享到其他应用

## 文件命名规则

导出的文件使用以下命名格式：
```
ze_memo_backup_YYYYMMDD_HHMM.json
```

示例：`ze_memo_backup_20251215_1430.json`

## 注意事项

1. **Android 11+ 的限制**：
   - 由于 Google 的存储政策，应用无法直接写入到系统公共下载目录
   - 文件会保存在应用专用的下载文件夹中
   - 用户仍可通过文件管理器访问这些文件

2. **权限要求**：
   - Android 需要存储权限
   - 首次使用时会自动请求权限

3. **文件管理器访问**：
   - Android：使用文件管理器，进入 "Android/data/com.lvlin.ze_memo/files/Downloads"
   - iOS：使用 "文件" App
   - 桌面端：直接访问系统下载目录