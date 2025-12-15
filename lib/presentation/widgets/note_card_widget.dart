import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../data/models/note_entry.dart';

class NoteCard extends StatefulWidget {
  final String date;
  final List<NoteEntry> entries;
  final bool initiallyExpanded;
  final bool? expandAll; // 全局控制展开状态

  const NoteCard({
    super.key,
    required this.date,
    required this.entries,
    this.initiallyExpanded = false,
    this.expandAll,
  });

  @override
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    // 初始化中文 locale
    initializeDateFormatting('zh_CN', null).then((_) {
      Intl.defaultLocale = 'zh_CN';
      if (mounted) setState(() {});
    });

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // 初始化展开状态
    _isExpanded = widget.initiallyExpanded;
    if (_isExpanded) {
      _animationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(NoteCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 只有在全局控制状态发生变化时才更新
    if (widget.expandAll != oldWidget.expandAll) {
      _updateExpansionState(widget.expandAll);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _updateExpansionState(bool? globalExpandState) async {
    if (globalExpandState == null) return;
    
    // ✅ 修复方案：根据目标状态播放相应动画
    if (globalExpandState) {
      // 目标为展开状态
      if (!_isExpanded) {
        await _animationController.forward();
      }
    } else {
      // 目标为收起状态  
      if (_isExpanded) {
        await _animationController.reverse();
      }
    }
    
    // 同步更新状态
    setState(() {
      _isExpanded = globalExpandState;
    });
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.15),
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // 卡片头部 - 点击展开/收起
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggleExpansion,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // 日期显示
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatDateHeader(widget.date),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.entries.length} 条笔记',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 展开/收起图标
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.expand_more,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 展开的笔记内容
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.entries.asMap().entries.map((entry) {
                  final index = entry.key;
                  final noteEntry = entry.value;

                  return Column(
                    children: [
                      // 单条笔记
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            _showNoteDetailDialog(noteEntry);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 时间标记
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    DateFormat('HH:mm').format(noteEntry.timestamp),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // 笔记内容
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: SelectableText(
                                    noteEntry.content,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // 笔记之间的间距
                      if (index < widget.entries.length - 1) const SizedBox(height: 2),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateHeader(String dateString) {
    final date = DateTime.parse(dateString);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final noteDate = DateTime(date.year, date.month, date.day);
    final difference = noteDate.difference(today).inDays;

    if (difference == 0) {
      // 今天的日期显示为 "今天 星期几" 格式
      return '今天 ${DateFormat('EEEE').format(date)}';
    } else {
      // 其他所有日期显示为 "年-月-日，星期几" 格式
      return '${DateFormat('yyyy年M月d日').format(date)}，${DateFormat('EEEE').format(date)}';
    }
  }

  void _showNoteDetailDialog(NoteEntry noteEntry) {
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
            Text(
              _formatDetailDateTime(noteEntry.timestamp),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            SelectableText(
              noteEntry.content,
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

  String _formatDetailDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final noteDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final difference = noteDate.difference(today).inDays;

    final timeStr = DateFormat('HH:mm').format(dateTime);

    if (difference == 0) {
      // 今天的日期显示为 "今天 星期几 时间" 格式
      return '今天 ${DateFormat('EEEE').format(dateTime)} $timeStr';
    } else {
      // 其他所有日期显示为 "年-月-日，星期几 时间" 格式
      return '${DateFormat('yyyy年M月d日').format(dateTime)}，${DateFormat('EEEE').format(dateTime)} $timeStr';
    }
  }
}