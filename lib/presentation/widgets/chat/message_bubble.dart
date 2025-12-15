import 'package:flutter/material.dart';
import '../../providers/chat_provider.dart';
import '../../../data/models/classification_result.dart';
import '../../../data/models/chat_message.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onRetry;

  const MessageBubble({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            AvatarWidget(
              state: message.state,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.70,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
                      bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 消息内容
                      if (message.content.isEmpty && message.state == ChatState.processing)
                        SelectableText(
                          '正在思考...',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isUser
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      else
                        SelectableText(
                          message.content,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isUser
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),

                      // 分类结果
                      if (message.classification != null) ...[
                        const SizedBox(height: 8),
                        _buildClassificationTag(context, message.classification!),
                      ],

                      // 错误信息
                      if (message.state == ChatState.error && message.error != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 16,
                              color: isUser
                                  ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.8)
                                  : Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                message.error!,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: isUser
                                      ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.8)
                                      : Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // 时间戳和状态
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(message.timestamp),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                    if (!isUser) ...[
                      const SizedBox(width: 8),
                      _buildStatusIcon(context, message.state),
                    ],
                    if (!isUser && message.state == ChatState.error && onRetry != null) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onRetry,
                        child: Icon(
                          Icons.refresh,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue,
              child: Icon(
                Icons.person,
                size: 20,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildClassificationTag(BuildContext context, ClassificationResult classification) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: classification.isNewCategory
            ? Colors.green.withOpacity(0.2)
            : Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: classification.isNewCategory
              ? Colors.green.withOpacity(0.5)
              : Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            classification.isNewCategory ? Icons.add_circle_outline : Icons.label_outline,
            size: 14,
            color: classification.isNewCategory
                ? Colors.green
                : Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              classification.displayName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: classification.isNewCategory
                    ? Colors.green
                    : Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (classification.isNewCategory) ...[
            const SizedBox(width: 4),
            Text(
              ' (新)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIcon(BuildContext context, ChatState state) {
    switch (state) {
      case ChatState.processing:
        return SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: Theme.of(context).colorScheme.primary,
          ),
        );
      case ChatState.success:
        return Icon(
          Icons.check_circle,
          size: 16,
          color: Theme.of(context).colorScheme.primary,
        );
      case ChatState.error:
        return Icon(
          Icons.error,
          size: 16,
          color: Theme.of(context).colorScheme.error,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}小时前';
    } else {
      return '${time.month}/${time.day} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}

// AI头像组件
class AvatarWidget extends StatelessWidget {
  final ChatState state;

  const AvatarWidget({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      child: Icon(
        Icons.smart_toy_outlined,
        size: 20,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}