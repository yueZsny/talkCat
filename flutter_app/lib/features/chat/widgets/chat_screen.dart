import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../../core/api/api_client.dart';
import '../../character/providers/character_provider.dart';
import '../../character/models/character_state.dart';
import '../../character/widgets/character_widget.dart';
import '../providers/chat_provider.dart';
import '../models/message.dart';
import 'chat_bubble.dart';
import 'chat_input.dart';
import 'package:shimmer/shimmer.dart';

/// 聊天界面 — 与宠物对话
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  Timer? _thinkingTimer;
  final ApiClient _api = ApiClient();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(characterProvider.notifier).greet();
      if (ref.read(chatProvider).isEmpty) {
        ref.read(chatProvider.notifier).addPetMessage('嗨！我是小暖，你的陪伴小宠物～有什么想聊的吗？😊');
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _thinkingTimer?.cancel();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final chatNotifier = ref.read(chatProvider.notifier);

    chatNotifier.addUserMessage(text);
    _scrollToBottom();

    ref.read(characterProvider.notifier).setEmotion(PetEmotion.thinking);
    ref.read(chatLoadingProvider.notifier).state = true;

    // 从历史记录生成上下文
    final history = ref.read(chatProvider)
        .where((m) => m.role != MessageRole.system)
        .map((m) => {'role': m.isUser ? 'user' : 'pet', 'content': m.content})
        .toList();

    try {
      // 调用后端 DeepSeek API
      final response = await _api.post('/chat', data: {
        'message': text,
        'history': history,
      });

      if (!mounted) return;

      final data = response.data as Map<String, dynamic>;
      final reply = (data['message'] as Map<String, dynamic>)['content'] as String? ?? '';
      final emotion = data['emotion'] as String? ?? 'idle';

      // 显示回复
      await _displayReply(reply, emotion);
    } catch (e) {
      print('[Chat] API 调用失败: $e');
      if (!mounted) return;

      // 网络失败时使用本地兜底回复
      final fallback = _localFallback(text);
      await _displayReply(fallback, 'idle');
    }
  }

  Future<void> _displayReply(String reply, String emotion) async {
    final chatNotifier = ref.read(chatProvider.notifier);
    final characterNotifier = ref.read(characterProvider.notifier);

    // 宠物开始说话
    characterNotifier.startTalking();
    chatNotifier.addPetMessage('');

    // 逐字输出效果
    for (int i = 0; i < reply.length; i++) {
      await Future.delayed(const Duration(milliseconds: 30));
      if (!mounted) return;
      chatNotifier.removeLast();
      chatNotifier.addPetMessage(reply.substring(0, i + 1));
      _scrollToBottom();
    }

    characterNotifier.inferEmotionFromText(reply);
    ref.read(chatLoadingProvider.notifier).state = false;
  }

  /// 语音回复回调
  void _handleVoiceReply(String reply, String emotion) {
    ref.read(chatProvider.notifier).addPetMessage(reply);
    ref.read(characterProvider.notifier).inferEmotionFromText(reply);
    ref.read(chatLoadingProvider.notifier).state = false;
    _scrollToBottom();
  }

  /// 后端不可用时的本地兜底
  String _localFallback(String message) {
    final keywords = {
      '开心': '看到你开心我也超开心的！🥰',
      '高兴': '哇～好棒呀！今天有什么好事呀？😄',
      '难过': '不要难过啦～有我在呢！抱抱你 🤗',
      '伤心': '不要伤心啦，我来给你讲个笑话吧～',
      '晚安': '晚安呀～好梦哦！明天见 🌙',
      '哈哈': '哈哈～你笑起来真好看！😊',
      '饿': '诶～说到吃的我也饿了！喜欢甜点吗 🍰',
    };
    for (final entry in keywords.entries) {
      if (message.contains(entry.key)) return entry.value;
    }
    return '嗯嗯～我在听呢！你继续说～👂';
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatProvider);
    final isLoading = ref.watch(chatLoadingProvider);
    final characterState = ref.watch(characterProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () {
            ref.read(characterProvider.notifier).setEmotion(PetEmotion.idle);
            context.pop();
          },
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '小暖',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              characterState.emotion.label,
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (messages.isEmpty)
            Container(
              height: 140,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: const Center(
                child: SizedBox(
                  width: 100,
                  height: 120,
                  child: CharacterWidget(),
                ),
              ),
            ),
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '来和我聊聊天吧 🎀',
                          style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '点击下方输入框开始对话',
                          style: TextStyle(fontSize: 13, color: Colors.grey[300]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: messages.length + (isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= messages.length) {
                        return _buildLoadingIndicator();
                      }
                      return ChatBubble(message: messages[index]);
                    },
                  ),
          ),
          ChatInput(
            onSend: _sendMessage,
            onVoiceReply: _handleVoiceReply,
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFFF8C94).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(child: Text('🐱', style: TextStyle(fontSize: 16))),
          ),
          const SizedBox(width: 8),
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: 80,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
