import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../character/providers/character_provider.dart';
import '../../character/models/character_state.dart';
import '../../character/widgets/character_widget.dart';
import '../providers/chat_provider.dart';
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

  @override
  void initState() {
    super.initState();
    // 进入聊天时自动打招呼
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
    final characterNotifier = ref.read(characterProvider.notifier);

    // 添加用户消息
    chatNotifier.addUserMessage(text);
    _scrollToBottom();

    // 宠物进入思考状态
    characterNotifier.setEmotion(PetEmotion.thinking);
    ref.read(chatLoadingProvider.notifier).state = true;

    // 模拟 AI 思考时间（后续替换为真实 API 调用）
    _thinkingTimer = Timer(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      _generateResponse(text);
    });
  }

  Future<void> _generateResponse(String userMessage) async {
    final chatNotifier = ref.read(chatProvider.notifier);
    final characterNotifier = ref.read(characterProvider.notifier);

    // 从情绪推断和简单规则生成回复
    // TODO: Phase 1.2 替换为真实 LLM API 调用
    final response = await _callLLM(userMessage);

    // 宠物开始说话
    characterNotifier.startTalking();

    // 模拟逐字输出效果
    chatNotifier.addPetMessage('');

    for (int i = 0; i < response.length; i++) {
      await Future.delayed(const Duration(milliseconds: 30));
      if (!mounted) return;
      chatNotifier.removeLast();
      chatNotifier.addPetMessage(response.substring(0, i + 1));
      _scrollToBottom();
    }

    // 根据回复内容推断情绪
    characterNotifier.inferEmotionFromText(response);

    ref.read(chatLoadingProvider.notifier).state = false;
  }

  /// 调用后端 LLM 服务（当前为本地模拟，后续替换为真实 API）
  Future<String> _callLLM(String message) async {
    // TODO: 替换为真实的 API 调用
    await Future.delayed(const Duration(milliseconds: 500));

    final lower = message.toLowerCase();
    if (lower.contains('开心') || lower.contains('高兴') || lower.contains('今天')) {
      return '今天我也很开心呀！能和你聊天是最幸福的事～🥰\n\n有什么好玩的事情想跟我分享吗？';
    }
    if (lower.contains('难过') || lower.contains('伤心') || lower.contains('哭')) {
      return '不要难过啦，我在这里陪着你呢 🤗\n\n要不要我给你讲个笑话或者抱抱你？';
    }
    if (lower.contains('名字') || lower.contains('你是谁')) {
      return '我叫小暖！是你的专属陪伴小宠物～\n\n我会一直在这里陪着你，听你说话，逗你开心！✨';
    }
    if (lower.contains('晚安') || lower.contains('睡了')) {
      return '晚安～好梦哦！🌙\n\n明天我还会在这里等你的，要梦到我哦～😴💤';
    }
    if (lower.contains('饿') || lower.contains('吃')) {
      return '诶！说到吃的我也好馋呀～\n\n你最喜欢吃什么呀？我也想吃吃看！🍰';
    }
    if (lower.contains('歌') || lower.contains('唱')) {
      return '嗯…让我想想唱什么好呢～🎵\n\n（清清嗓子）啦啦啦～小暖爱唱歌，唱歌给你听～♪\n\n好听吗？嘿嘿～😄';
    }

    // 默认回复
    final defaultResponses = [
      '嗯嗯，我在听呢！你说～👂',
      '原来是这样呀！然后呢然后呢？😃',
      '哇！真的吗？好有意思呀～✨',
      '嘿嘿，我在认真听你说话哦～💕',
      '对呀对呀，你说得太对了！😄',
    ];
    return defaultResponses[DateTime.now().millisecond % defaultResponses.length];
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
            Navigator.pop(context);
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
          // 小尺寸宠物展示
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
          // 消息列表
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '来和我聊聊天吧 🎀',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[400],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '点击下方输入框开始对话',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[300],
                          ),
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
          // 输入区
          ChatInput(
            onSend: _sendMessage,
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
            child: const Center(
              child: Text('🐱', style: TextStyle(fontSize: 16)),
            ),
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
