import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/chat_provider.dart';
import '../providers/notes_provider.dart';
import '../providers/app_update_provider.dart';
import '../../core/utils/app_update_helper.dart';
import '../../core/config/update_config.dart';
import 'chat_page.dart';
import 'notes_page.dart';
import '../../core/services/import_export_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    // 初始化 TabController
    _tabController = TabController(length: 2, vsync: this);

    // 添加监听器以处理页面切换逻辑
    _tabController.addListener(_handleTabSelection);

    _pages = [const ChatPage(), const NotesPage()];

    // 延迟执行更新检查，确保UI已经渲染完成
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
    });
  }

  /// 处理Tab切换
  void _handleTabSelection() {
    setState(() {
      // 触发重绘以更新AppBar actions
    });

    // 确保只在切换完成时触发（避免滑动过程中的多次触发）
    if (!_tabController.indexIsChanging) {
      // 切换到笔记页面(index 1)时自动刷新
      if (_tabController.index == 1) {
        context.read<NotesProvider>().refreshNotes();
      }
    }
  }

  void _showApiKeyDialog() {
    final textController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('配置API密钥'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('请输入您的DeepSeek API密钥'),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                labelText: 'API密钥',
                border: OutlineInputBorder(),
                hintText: 'sk-...',
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final apiKey = textController.text.trim();
              if (apiKey.isNotEmpty) {
                context.read<ChatProvider>().setApiKey(apiKey);
                Navigator.of(context).pop();
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showClearAllDialog(ChatProvider chatProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空所有对话'),
        content: const Text('确定要清空所有对话记录吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              chatProvider.clearAllMessages();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _exportNotes(NotesProvider provider) async {
    try {
      // 显示加载中提示
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('正在准备导出...')));

      // 使用导入导出服务
      final success = await ImportExportService.exportNotesToFile(
        noteFiles: provider.noteFiles,
        context: context,
      );

      if (success) {
        // 导出成功已在服务内部处理
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('导出失败：${e.toString()}')));
    }
  }

  void _importNotes(NotesProvider provider) async {
    try {
      // 使用导入导出服务
      final importData = await ImportExportService.importNotesFromFile(
        context: context,
      );

      if (importData != null) {
        // 显示加载中提示
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('正在导入笔记...')));

        // 调用provider的导入方法
        final success = await provider.importNotes(importData);

        if (success) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('导入成功')));
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('导入失败')));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('导入失败：${e.toString()}')));
    }
  }

  void _cleanEmptyFiles(NotesProvider provider) async {
    final cleanedCount = await provider.cleanEmptyFiles();
    if (cleanedCount > 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('已清理 $cleanedCount 个空文件')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('没有找到空文件')));
    }
  }

  void _showStatsDialog(NotesProvider provider) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题栏
              Row(
                children: [
                  Icon(
                    Icons.analytics,
                    size: 24,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '统计信息',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    tooltip: '关闭',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              // 统计内容
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 存储统计
                      _buildStatsSection('存储统计', [
                        _buildStatRow(
                          '文件数量',
                          '${provider.stats['totalFiles']}',
                        ),
                        _buildStatRow(
                          '笔记总数',
                          '${provider.stats['totalEntries']}',
                        ),
                        _buildStatRow(
                          '占用空间',
                          provider.stats['totalSizeFormatted'],
                        ),
                      ]),
                      const SizedBox(height: 16),
                      // 类别统计
                      _buildStatsSection(
                        '类别统计',
                        provider.getCategoryStats().entries.map((entry) {
                          return _buildStatRow(entry.key, '${entry.value} 条');
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  List<Widget> _buildActions() {
    if (_tabController.index == 0) {
      // Chat Page Actions
      return [
        Consumer<ChatProvider>(
          builder: (context, chatProvider, child) {
            return PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'configure_api':
                    _showApiKeyDialog();
                    break;
                  case 'clear_all':
                    _showClearAllDialog(chatProvider);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'configure_api',
                  child: Row(
                    children: [
                      Icon(Icons.key_outlined),
                      SizedBox(width: 8),
                      Text('配置API密钥'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(Icons.clear_all_outlined),
                      SizedBox(width: 8),
                      Text('清空对话'),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ];
    } else {
      // Notes Page Actions
      return [
        PopupMenuButton<String>(
          onSelected: (value) {
            final provider = context.read<NotesProvider>();
            switch (value) {
              case 'refresh':
                provider.refreshNotes();
                break;
              case 'export':
                _exportNotes(provider);
                break;
              case 'import':
                _importNotes(provider);
                break;
              case 'clean_empty':
                _cleanEmptyFiles(provider);
                break;
              case 'stats':
                _showStatsDialog(provider);
                break;
              case 'check_update':
                AppUpdateHelper.checkAndShowUpdate(
                  context,
                  owner: UpdateConfig.giteeOwner,
                  repo: UpdateConfig.giteeRepo,
                  showNoUpdateDialog: true,
                  isManual: true,
                );
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'refresh',
              child: Row(
                children: [Icon(Icons.refresh), SizedBox(width: 8), Text('刷新')],
              ),
            ),
            const PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.file_upload),
                  SizedBox(width: 8),
                  Text('导出笔记'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'import',
              child: Row(
                children: [
                  Icon(Icons.file_download),
                  SizedBox(width: 8),
                  Text('导入笔记'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'clean_empty',
              child: Row(
                children: [
                  Icon(Icons.cleaning_services),
                  SizedBox(width: 8),
                  Text('清理空文件'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'stats',
              child: Row(
                children: [
                  Icon(Icons.analytics),
                  SizedBox(width: 8),
                  Text('统计'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'check_update',
              child: Row(
                children: [
                  Icon(Icons.system_update),
                  SizedBox(width: 8),
                  Text('检查更新'),
                ],
              ),
            ),
          ],
        ),
      ];
    }
  }

  /// 检查应用更新
  void _checkForUpdates() async {
    debugPrint(
      '开始检查更新... Gitee: ${UpdateConfig.giteeOwner}/${UpdateConfig.giteeRepo}',
    );

    try {
      await AppUpdateHelper.checkAndShowUpdate(
        context,
        owner: UpdateConfig.giteeOwner,
        repo: UpdateConfig.giteeRepo,
        showNoUpdateDialog: false, // 无更新时不显示提示
      );
      debugPrint('更新检查完成');
    } catch (e) {
      // 静默处理错误，不影响用户体验
      debugPrint('检查更新失败: $e');
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          dividerColor: Colors.transparent,
          indicatorColor: Theme.of(context).primaryColor,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: const Color(0xFF111827), // textPrimary
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 16),
          tabs: const [
            Tab(text: '小助手'),
            Tab(text: '笔记浏览'),
          ],
        ),
        actions: _buildActions(),
      ),
      body: TabBarView(controller: _tabController, children: _pages),
    );
  }
}
