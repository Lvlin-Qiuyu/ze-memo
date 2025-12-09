import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/notes_provider.dart';
import '../../data/models/note_file.dart';
import '../../data/models/note_entry.dart';
import '../widgets/common/loading_widget.dart';
import '../widgets/common/error_widget.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(() {
      final query = _searchController.text;
      context.read<NotesProvider>().searchNotes(query);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
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
            Tab(text: '统计', icon: Icon(Icons.analytics)),
          ],
        ),
        actions: [
          Consumer<NotesProvider>(
            builder: (context, provider, child) {
              return IconButton(
                onPressed: () => _showSearchDialog(provider),
                icon: const Icon(Icons.search),
              );
            },
          ),
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
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCategoryView(),
          _buildTimelineView(),
          _buildStatsView(),
        ],
      ),
    );
  }

  Widget _buildCategoryView() {
    return Consumer<NotesProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const LoadingWidget(message: '加载笔记中...');
        }

        if (provider.noteFiles.isEmpty) {
          return CustomErrorWidget(
            error: '暂无笔记记录',
            icon: Icons.note_outlined,
            action: ElevatedButton(
              onPressed: () {
                // 切换到聊天页面
                DefaultTabController.of(context).animateTo(0);
              },
              child: const Text('开始记录'),
            ),
          );
        }

        final selectedFile = provider.selectedNoteFile;

        return Row(
          children: [
            // 左侧类别列表
            SizedBox(
              width: 200,
              child: ListView.builder(
                itemCount: provider.noteFiles.length,
                itemBuilder: (context, index) {
                  final file = provider.noteFiles[index];
                  final isSelected = selectedFile?.category == file.category;

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    elevation: isSelected ? 4 : 1,
                    child: ListTile(
                      selected: isSelected,
                      title: Text(
                        file.title,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text('${file.totalEntries} 条笔记'),
                      trailing: isSelected
                          ? Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : null,
                      onTap: () => provider.selectCategory(file.category),
                      onLongPress: () => _showDeleteCategoryDialog(provider, file),
                    ),
                  );
                },
              ),
            ),
            // 分割线
            const VerticalDivider(width: 1),
            // 右侧详情
            Expanded(
              child: selectedFile != null
                  ? _buildNoteDetail(selectedFile)
                  : const Center(
                      child: Text('选择一个类别查看详情'),
                    ),
            ),
          ],
        );
      },
    );
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
              child: ListTile(
                title: Text(entry.content),
                subtitle: Text(
                  DateFormat('yyyy-MM-dd HH:mm').format(entry.timestamp),
                ),
                onTap: () => _showNoteDetailDialog(entry),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatsView() {
    return Consumer<NotesProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const LoadingWidget(message: '加载统计信息...');
        }

        final stats = provider.stats;
        final categoryStats = provider.getCategoryStats();
        final monthlyStats = provider.getMonthlyStats();
        final hotWords = provider.getHotWords();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 存储统计
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '存储统计',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      _buildStatRow('文件数量', '${stats['totalFiles']}'),
                      _buildStatRow('笔记总数', '${stats['totalEntries']}'),
                      _buildStatRow('占用空间', stats['totalSizeFormatted']),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 类别统计
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '类别统计',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      ...categoryStats.entries.map((entry) {
                        return _buildStatRow(
                          entry.key,
                          '${entry.value} 条',
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 热词统计
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '热词排行',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: hotWords.entries.take(20).map((entry) {
                          return Chip(
                            label: Text('${entry.key} (${entry.value})'),
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.1),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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

  void _showSearchDialog(NotesProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('搜索笔记'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            labelText: '输入关键词',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              provider.clearSearch();
              Navigator.of(context).pop();
            },
            child: const Text('清除'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
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
        title: const Text('笔记详情'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entry.content),
            const SizedBox(height: 16),
            Text(
              '创建时间: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(entry.timestamp)}',
              style: Theme.of(context).textTheme.bodySmall,
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