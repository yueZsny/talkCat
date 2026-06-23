/// 消息角色
enum MessageRole { user, pet, system }

/// 消息模型
class ChatMessage {
  final String id;
  final MessageRole role;
  final String content;
  final DateTime createdAt;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    DateTime? createdAt,
    this.isRead = true,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 是否是用户消息
  bool get isUser => role == MessageRole.user;

  /// 是否是宠物消息
  bool get isPet => role == MessageRole.pet;

  ChatMessage copyWith({
    String? id,
    MessageRole? role,
    String? content,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'role': role.name,
    'content': content,
    'created_at': createdAt.toIso8601String(),
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] as String,
    role: MessageRole.values.byName(json['role'] as String),
    content: json['content'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}
