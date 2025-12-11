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
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredDates = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _filteredDates = widget.noteFile.entriesByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _isSearching = query.isNotEmpty;
      if (_isSearching) {
        _filteredDates = widget.noteFile.entriesByDate.entries
            .where((entry) => entry.value
                .any((note) => note.content.toLowerCase().contains(query)))
            .map((entry) => entry.key)
            .toList()
          ..sort((a, b) => b.compareTo(a));
      } else {
        _filteredDates = widget.noteFile.entriesByDate.keys.toList()
          ..sort((a, b) => b.compareTo(a));
      }
    });
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
              // 搜索按钮
              IconButton(
                icon: Icon(_isSearching ? Icons.close : Icons.search),
                onPressed: () {
                  if (_isSearching) {
                    _searchController.clear();
                  } else {
                    setState(() {});
                  }
                },
              ),
              // 更多菜单
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
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
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('编辑类别'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(Icons.download),
                        SizedBox(width: 8),
                        Text('导出笔记'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete),
                        SizedBox(width: 8),
                        Text('删除类别'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          // 搜索栏
          if (_isSearching)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: '搜索笔记内容...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _searchController.clear(),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
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
                  _isSearching ? '没有找到匹配的笔记' : '该类别暂无笔记',
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
                  final entries = _isSearching
                      ? widget.noteFile.entriesByDate[date]!
                          .where((entry) => entry.content
                              .toLowerCase()
                              .contains(_searchController.text.toLowerCase()))
                          .toList()
                      : widget.noteFile.entriesByDate[date]!;

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