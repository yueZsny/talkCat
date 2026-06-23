import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message.dart';

/// 对话状态 Provider
class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  ChatNotifier() : super([]);

  /// 添加用户消息
  void addUserMessage(String content) {
    final msg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.user,
      content: content,
    );
    state = [...state, msg];
  }

  /// 添加宠物消息
  void addPetMessage(String content) {
    final msg = ChatMessage(
      id: 'pet_${DateTime.now().millisecondsSinceEpoch.toString()}',
      role: MessageRole.pet,
      content: content,
    );
    state = [...state, msg];
  }

  /// 添加系统消息
  void addSystemMessage(String content) {
    final msg = ChatMessage(
      id: 'sys_${DateTime.now().millisecondsSinceEpoch.toString()}',
      role: MessageRole.system,
      content: content,
    );
    state = [...state, msg];
  }

  /// 获取最后一条消息（用于 AI 回复的上下文）
  String get lastUserMessage {
    final userMessages = state.where((m) => m.isUser).toList();
    return userMessages.isNotEmpty ? userMessages.last.content : '';
  }

  /// 获取对话历史（用于 API 调用）
  List<Map<String, String>> get history => state
      .where((m) => m.role != MessageRole.system)
      .map((m) => {'role': m.role.name, 'content': m.content})
      .toList();

  /// 清空对话
  void clear() => state = [];

  /// 移除最后一条消息（用于撤回）
  void removeLast() {
    if (state.isNotEmpty) {
      state = [...state.sublist(0, state.length - 1)];
    }
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatMessage>>((ref) {
  return ChatNotifier();
});

/// 对话加载状态
final chatLoadingProvider = StateProvider<bool>((ref) => false);

/// WebSocket 连接状态
final connectionStateProvider = StateProvider<bool>((ref) => false);
