import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/notes_provider.dart';
import '../widgets/note_card_widget.dart';
import '../../data/models/note_file.dart';

class CategoryDetailPage extends StatefulWidget {
  final NoteFile noteFile;

  const CategoryDetailPage({
    super.key,
    required this.noteFile,
  });

  @override
  State<CategoryDetailPage> createState() => _CategoryDetailPageState();
}

class _CategoryDetailPageState extends State<CategoryDetailPage> {
  final ScrollController _scrollController = ScrollController();
  List<String> _filteredDates = [];

  @override
  void initState() {
    super.initState();
    _filteredDates = widget.noteFile.entriesByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7), // 浅灰色背景
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // 自定义 AppBar
          SliverAppBar(
            expandedHeight: 80,
            floating: false,
            pinned: true,
            backgroundColor: _getCategoryColor(context),
            foregroundColor: Colors.white, // 设置图标和文字为白色
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.zero,
              title: Container(
                padding: const EdgeInsets.only(
                  left: 40,
                  top: 5,
                  bottom: 5,
                  right: 40,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.noteFile.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    if (widget.noteFile.description.isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(
                        widget.noteFile.description,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 9,
                        ),
                      ),
                    ],
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '${widget.noteFile.totalEntries} 条笔记',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '·',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${widget.noteFile.entriesByDate.length} 天记录',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 8,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _getCategoryColor(context),
                      _getCategoryColor(context).withOpacity(0.8),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              // 更多菜单
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _editCategory();
                      break;
                    case 'delete':
                      _deleteCategory();
                      break;
                    case 'export':
                      _exportCategory();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: Colors.black),
                        SizedBox(width: 8),
                        Text('编辑类别'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(Icons.download, color: Colors.black),
                        SizedBox(width: 8),
                        Text('导出笔记'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.black),
                        SizedBox(width: 8),
                        Text('删除类别'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          // 添加一些间距
          const SliverToBoxAdapter(
            child: SizedBox(height: 8),
          ),
          // 笔记列表
          if (_filteredDates.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  '该类别暂无笔记',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final date = _filteredDates[index];
                  final entries = widget.noteFile.entriesByDate[date]!;

                  return NoteCard(
                    date: date,
                    entries: entries,
                    initiallyExpanded: index == 0,
                  );
                },
                childCount: _filteredDates.length,
              ),
            ),
        ],
      ),
    );
  }

  
  Color _getCategoryColor(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  IconData _getCategoryIcon() {
    switch (widget.noteFile.category.toLowerCase()) {
      case 'work':
        return Icons.work;
      case 'study':
        return Icons.school;
      case 'life':
        return Icons.favorite;
      default:
        return Icons.folder;
    }
  }

  void _editCategory() {
    // TODO: 实现编辑类别功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('编辑功能开发中')),
    );
  }

  void _deleteCategory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除类别'),
        content: Text('确定要删除类别"${widget.noteFile.title}"吗？\n这将删除该类别下的所有笔记，且无法恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              Provider.of<NotesProvider>(context, listen: false)
                  .deleteCategory(widget.noteFile.category);
              Navigator.of(context).pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _exportCategory() {
    // TODO: 实现导出功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('导出功能开发中')),
    );
  }
}