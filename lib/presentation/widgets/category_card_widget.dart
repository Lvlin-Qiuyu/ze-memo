import 'package:flutter/material.dart';
import '../../data/models/note_file.dart';

class CategoryCard extends StatelessWidget {
  final NoteFile noteFile;
  final VoidCallback onTap;
  final bool isSelected;

  const CategoryCard({
    super.key,
    required this.noteFile,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    // 检测屏幕宽度，决定是否显示图标
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompactMode = screenWidth < 600; // 窄屏设备（手机竖屏）

    return Hero(
      tag: 'category-${noteFile.category}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: isCompactMode
            ? _buildCompactLayout(context)
            : _buildNormalLayout(context),
        ),
      ),
    );
  }

  // 正常布局（宽屏）
  Widget _buildNormalLayout(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 140),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getCategoryColor(context).withOpacity(0.1),
            _getCategoryColor(context).withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
              : Theme.of(context).colorScheme.outline.withOpacity(0.1),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 图标和箭头
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getCategoryColor(context).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getCategoryIcon(),
                  color: _getCategoryColor(context),
                  size: 24,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 标题
          Text(
            noteFile.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          // 描述
          Text(
            noteFile.description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          // 统计信息
          Row(
            children: [
              Icon(
                Icons.article_outlined,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              const SizedBox(width: 4),
              Text(
                '${noteFile.totalEntries} 条笔记',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const Spacer(),
              Text(
                '更新于 ${_formatDate(noteFile.updatedAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 紧凑布局（窄屏）
  Widget _buildCompactLayout(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isSelected
            ? _getCategoryColor(context).withOpacity(0.1)
            : Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
              : Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 小图标
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getCategoryColor(context).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getCategoryIcon(),
              color: _getCategoryColor(context),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // 标题、描述和统计信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 标题
                Text(
                  noteFile.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // 描述
                if (noteFile.description.isNotEmpty) ...[
                  Text(
                    noteFile.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                ],
                // 统计信息
                Text(
                  '${noteFile.totalEntries} 条笔记',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          // 右侧箭头
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Icon(
              Icons.chevron_right,
              size: 20,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(BuildContext context) {
    // 使用哈希值生成一致的颜色
    final hash = noteFile.category.hashCode;
    final colors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF10B981), // Emerald
      const Color(0xFFF59E0B), // Amber
      const Color(0xFFEF4444), // Red
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFEC4899), // Pink
      const Color(0xFF14B8A6), // Teal
      const Color(0xFFF97316), // Orange
    ];
    return colors[hash.abs() % colors.length];
  }

  IconData _getCategoryIcon() {
    // 使用哈希值生成一致的图标
    final hash = noteFile.category.hashCode;
    final icons = [
      Icons.folder_outlined,
      Icons.bookmark_outline,
      Icons.label_outline,
      Icons.star_outline,
      Icons.chat_bubble_outline,
      Icons.lightbulb_outline,
      Icons.event_note,
      Icons.description_outlined,
    ];
    return icons[hash.abs() % icons.length];
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '今天';
    } else if (difference.inDays == 1) {
      return '昨天';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} 天前';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} 周前';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()} 个月前';
    } else {
      return '${date.year}年';
    }
  }
}