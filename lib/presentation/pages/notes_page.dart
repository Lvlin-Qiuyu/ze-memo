import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/notes_provider.dart';
import '../../data/models/note_file.dart';
import '../../data/models/note_entry.dart';
import '../widgets/common/loading_widget.dart';
import '../widgets/common/error_widget.dart';
import 'category_grid_page.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // 搜索相关代码已移除

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // 搜索监听器已移除
  }

  @override
  void dispose() {
    _tabController.dispose();
    // 搜索控制器已移除
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('笔记浏览'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '按类别', icon: Icon(Icons.category)),
            Tab(text: '按时间', icon: Icon(Icons.schedule)),
          ],
        ),
        actions: [
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
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('刷新'),
                  ],
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
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCategoryView(),
          _buildTimelineView(),
        ],
      ),
    );
  }

  Widget _buildCategoryView() {
    // 直接返回类别网格页面
    return const CategoryGridPage();
  }

  Widget _buildNoteDetail(NoteFile noteFile) {
    return Column(
      children: [
        // 标题区域
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                noteFile.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                noteFile.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '更新于 ${DateFormat('yyyy-MM-dd HH:mm').format(noteFile.updatedAt)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // 笔记列表
        Expanded(
          child: noteFile.entriesByDate.isEmpty
              ? const Center(
                  child: Text('该类别暂无笔记'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: noteFile.entriesByDate.length,
                  itemBuilder: (context, index) {
                    final date = noteFile.entriesByDate.keys.elementAt(index);
                    final entries = noteFile.entriesByDate[date]!;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ExpansionTile(
                        title: Text(
                          _formatDateHeader(date),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text('${entries.length} 条笔记'),
                        children: entries.map((entry) {
                          return ListTile(
                            title: Text(entry.content),
                            subtitle: Text(
                              DateFormat('HH:mm').format(entry.timestamp),
                            ),
                            onTap: () => _showNoteDetailDialog(entry),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTimelineView() {
    return Consumer<NotesProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const LoadingWidget(message: '加载中...');
        }

        final allEntries = provider.allEntriesByTime;

        if (allEntries.isEmpty) {
          return CustomErrorWidget(
            error: '暂无笔记记录',
            icon: Icons.schedule_outlined,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: allEntries.length,
          itemBuilder: (context, index) {
            final entry = allEntries[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showNoteDetailDialog(entry),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 时间标记 - 置灰缩小字体
                        Text(
                          DateFormat('yyyy-MM-dd HH:mm').format(entry.timestamp),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // 笔记内容
                        Text(
                          entry.content,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }



  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  String _formatDateHeader(String dateString) {
    final date = DateTime.parse(dateString);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final noteDate = DateTime(date.year, date.month, date.day);

    if (noteDate == today) {
      return '今天';
    } else if (noteDate == yesterday) {
      return '昨天';
    } else {
      return DateFormat('MM月dd日 EEEE').format(date);
    }
  }



  void _showDeleteCategoryDialog(NotesProvider provider, NoteFile file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除类别'),
        content: Text('确定要删除类别"${file.title}"吗？\n该类别下的所有笔记将被永久删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deleteNoteFile(file.category);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _showNoteDetailDialog(NoteEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '笔记详情',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 时间在上
            Text(
              _formatDetailDateTime(entry.timestamp),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            // 内容在下
            Text(
              entry.content,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _showStatsDialog(NotesProvider provider) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
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
                      _buildStatsSection(
                        '存储统计',
                        [
                          _buildStatRow('文件数量', '${provider.stats['totalFiles']}'),
                          _buildStatRow('笔记总数', '${provider.stats['totalEntries']}'),
                          _buildStatRow('占用空间', provider.stats['totalSizeFormatted']),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // 类别统计
                      _buildStatsSection(
                        '类别统计',
                        provider.getCategoryStats().entries.map((entry) {
                          return _buildStatRow(
                            entry.key,
                            '${entry.value} 条',
                          );
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
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  String _formatDetailDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final noteDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final difference = noteDate.difference(today).inDays;

    final timeStr = DateFormat('HH:mm').format(dateTime);

    if (difference == 0) {
      return '今天 $timeStr';
    } else if (difference == -1) {
      return '昨天 $timeStr';
    } else if (difference > -7) {
      return '${DateFormat('EEEE').format(dateTime)} $timeStr';
    } else {
      return DateFormat('M月d日 HH:mm').format(dateTime);
    }
  }

  void _exportNotes(NotesProvider provider) async {
    final exportData = await provider.exportAllNotes();
    if (exportData != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('导出成功')),
      );
    }
  }

  void _importNotes(NotesProvider provider) async {
    // 这里应该实现文件选择逻辑
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('导入功能开发中')),
    );
  }

  void _cleanEmptyFiles(NotesProvider provider) async {
    final cleanedCount = await provider.cleanEmptyFiles();
    if (cleanedCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已清理 $cleanedCount 个空文件')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有找到空文件')),
      );
    }
  }
}