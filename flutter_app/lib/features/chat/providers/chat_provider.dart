import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../models/message.dart';

/// 对话状态 Provider
class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  ChatNotifier() : super([]);

  void addUserMessage(String content) {
    final msg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.user,
      content: content,
    );
    state = [...state, msg];
  }

  void addPetMessage(String content) {
    final msg = ChatMessage(
      id: 'pet_${DateTime.now().millisecondsSinceEpoch.toString()}',
      role: MessageRole.pet,
      content: content,
    );
    state = [...state, msg];
  }

  void addSystemMessage(String content) {
    final msg = ChatMessage(
      id: 'sys_${DateTime.now().millisecondsSinceEpoch.toString()}',
      role: MessageRole.system,
      content: content,
    );
    state = [...state, msg];
  }

  String get lastUserMessage {
    final userMessages = state.where((m) => m.isUser).toList();
    return userMessages.isNotEmpty ? userMessages.last.content : '';
  }

  void clear() => state = [];
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

/// 连接状态 — 自动检测后端健康
class ConnectionNotifier extends StateNotifier<bool> {
  Timer? _timer;
  final ApiClient _api = ApiClient();

  ConnectionNotifier() : super(false) {
    _startChecking();
  }

  void _startChecking() {
    _check();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _check());
  }

  Future<void> _check() async {
    final ok = await _api.healthCheck();
    if (ok != state) {
      state = ok;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final connectionStateProvider = StateNotifierProvider<ConnectionNotifier, bool>((ref) {
  return ConnectionNotifier();
});
