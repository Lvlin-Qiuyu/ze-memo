import 'classification_result.dart';

class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final ChatState state;
  final String? error;
  final ClassificationResult? classification;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    required this.state,
    this.error,
    this.classification,
  });

  ChatMessage copyWith({
    String? id,
    String? content,
    bool? isUser,
    DateTime? timestamp,
    ChatState? state,
    String? error,
    ClassificationResult? classification,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      state: state ?? this.state,
      error: error ?? this.error,
      classification: classification ?? this.classification,
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'state': state.name,
      'error': error,
      'classification': classification?.toJson(),
    };
  }

  // 从JSON创建实例
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      isUser: json['isUser'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      state: ChatState.values.firstWhere(
        (state) => state.name == json['state'],
        orElse: () => ChatState.idle,
      ),
      error: json['error'] as String?,
      classification: json['classification'] != null
          ? ClassificationResult.fromJson(json['classification'] as Map<String, dynamic>)
          : null,
    );
  }
}

enum ChatState {
  idle,
  sending,
  processing,
  success,
  error,
}