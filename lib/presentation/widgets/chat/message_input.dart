import 'package:flutter/material.dart';

class MessageInput extends StatefulWidget {
  final ValueChanged<String>? onSend;
  final ValueChanged<String>? onChanged;
  final bool isLoading;
  final String hintText;
  final TextEditingController? controller;

  const MessageInput({
    super.key,
    this.onSend,
    this.onChanged,
    this.isLoading = false,
    this.hintText = '输入笔记内容...',
    this.controller,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  late final TextEditingController _controller;
  bool _canSend = false;
  int _maxLines = 1;

  @override
  void initState() {
    super.initState();
    // 使用外部传入的控制器，如果没有则创建新的
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(() {
      final text = _controller.text.trim();
      final newCanSend = text.isNotEmpty && !widget.isLoading;

      if (_canSend != newCanSend) {
        setState(() {
          _canSend = newCanSend;
        });
      }

      widget.onChanged?.call(text);
    });
  }

  @override
  void dispose() {
    // 只有当控制器是内部创建时才销毁
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _handleSend() {
    if (_canSend && widget.onSend != null) {
      final text = _controller.text.trim();
      if (text.isNotEmpty) {
        widget.onSend!(text);
        _controller.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end, // 改为底部对齐
          children: [
            // 输入框
            Expanded(
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: 36, // 最小高度等于按钮高度
                  maxHeight: 160, // 最大高度
                ),
                child: TextField(
                  controller: _controller,
                  maxLines: null, // 允许无限行数
                  textCapitalization: TextCapitalization.sentences,
                  enabled: !widget.isLoading,
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: TextStyle(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.6),
                      fontSize: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8.5, // 减小垂直padding，使输入框高度更接近36px
                    ),
                    isDense: true,
                    alignLabelWithHint: true,
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4, // 调整行高
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 文字按钮
            GestureDetector(
              onTap: _canSend ? _handleSend : null,
              child: Container(
                height: 36, // 固定按钮高度
                constraints: const BoxConstraints(
                  minWidth: 56, // 最小宽度
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0), // 减小padding
                decoration: BoxDecoration(
                  color: _canSend
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(6), // 与输入框保持一致
                ),
                child: Center(
                  child: widget.isLoading
                      ? SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.onPrimary,
                            strokeWidth: 1.5,
                          ),
                        )
                      : Text(
                          '发送',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontSize: 12, // 更小的字体
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}