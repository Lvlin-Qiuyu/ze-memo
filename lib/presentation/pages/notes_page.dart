import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/notes_provider.dart';

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
  bool _isAllExpanded = false; // 全部展开状态

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: const EdgeInsets.all(4),
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 1,
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              labelColor: const Color(0xFF1F2937),
              unselectedLabelColor: const Color(0xFF6B7280),
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              unselectedLabelStyle: const TextStyle(fontSize: 14),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: '按类别'),
                Tab(text: '按时间'),
              ],
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [_buildCategoryView(), _buildTimelineView()],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryView() {
    // 直接返回类别网格页面
    return const CategoryGridPage();
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
                        SelectableText(
                          DateFormat(
                            'yyyy-MM-dd HH:mm',
                          ).format(entry.timestamp),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                              ),
                        ),
                        const SizedBox(height: 4),
                        // 笔记内容
                        SelectableText(
                          entry.content,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontSize: 14, color: Colors.black87),
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

  void _showNoteDetailDialog(NoteEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('笔记详情', style: Theme.of(context).textTheme.titleLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 时间在上
            SelectableText(
              _formatDetailDateTime(entry.timestamp),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            // 内容在下
            SelectableText(
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
}
