import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat/message_input.dart';
import '../widgets/chat/message_bubble.dart';

import '../../data/models/chat_message.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _showScrollToBottomButton = false;

  @override
  void initState() {
    super.initState();
    // 监听滚动变化
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // 监听滚动事件
  void _onScroll() {
    if (_scrollController.hasClients) {
      // 当距离底部超过100px时显示按钮
      final distanceFromBottom =
          _scrollController.position.maxScrollExtent - _scrollController.offset;
      final showButton = distanceFromBottom > 100;
      if (showButton != _showScrollToBottomButton) {
        setState(() {
          _showScrollToBottomButton = showButton;
        });
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // 设置浅灰色背景
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          return Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: chatProvider.messages.isEmpty
                        ? _buildEmptyState(chatProvider)
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.fromLTRB(
                              16,
                              16,
                              16,
                              30,
                            ), // 底部增加30px padding为输入框预留空间
                            itemCount: chatProvider.messages.length,
                            itemBuilder: (context, index) {
                              final message = chatProvider.messages[index];
                              return MessageBubble(
                                message: message,
                                onRetry: message.state == ChatState.error
                                    ? () =>
                                          chatProvider.retryMessage(message.id)
                                    : null,
                              );
                            },
                          ),
                  ),
                  MessageInput(
                    controller: _searchController,
                    isLoading: chatProvider.isLoading,
                    onSend: (text) {
                      chatProvider.sendMessage(text);
                      _scrollToBottom();
                    },
                  ),
                ],
              ),
              // 回到底部按钮
              Positioned(
                bottom: 120, // 输入框高度约70px + 额外50px间距
                left:
                    MediaQuery.of(context).size.width / 2 -
                    20, // 居中显示（圆形按钮直径40）
                child: AnimatedScale(
                  scale: _showScrollToBottomButton ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: 0.9),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: _scrollToBottom,
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ChatProvider chatProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              '开始记录您的笔记',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '输入任意内容，AI将自动为您分类整理',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onBackground.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (chatProvider.errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        chatProvider.errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: chatProvider.clearError,
                      icon: const Icon(Icons.close, size: 20),
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
