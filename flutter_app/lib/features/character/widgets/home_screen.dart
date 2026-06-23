import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/character_provider.dart';
import '../widgets/character_widget.dart';
import '../../chat/providers/chat_provider.dart';
import '../../voice/wake_word/wake_word_provider.dart';
import '../../voice/wake_word/wake_word_service.dart';

/// 首页 — 显示宠物角色 + 交互入口
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final characterState = ref.watch(characterProvider);
    final isConnected = ref.watch(connectionStateProvider);
    final petName = ref.watch(petNameProvider);
    final wakeState = ref.watch(wakeWordProvider);
    final isListening = wakeState == WakeWordState.listening;

    // 唤醒词检测到 → 自动导航到聊天
    ref.listen<WakeWordState>(wakeWordProvider, (prev, next) {
      if (next == WakeWordState.detected && prev != WakeWordState.detected) {
        ref.read(isPetActiveProvider.notifier).state = true;
        context.go('/chat');
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context, ref, petName, isConnected, isListening, wakeState),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isListening)
                      _buildListeningIndicator(context),
                    const CharacterWidget(),
                    const SizedBox(height: 8),
                    Text(
                      characterState.emotion.label,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            _buildWakeWordToggle(context, ref, wakeState),
            const SizedBox(height: 8),
            _buildBottomActions(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildListeningIndicator(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFA5D6A7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '正在倾听中，说句话试试 🎤',
            style: TextStyle(
              fontSize: 13,
              color: Colors.green[800],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWakeWordToggle(BuildContext context, WidgetRef ref, WakeWordState wakeState) {
    final bool isOn = wakeState == WakeWordState.listening;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: GestureDetector(
        onTap: () => ref.read(wakeWordProvider.notifier).toggle(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isOn ? const Color(0xFFE8F5E9) : Colors.grey[50],
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isOn ? const Color(0xFF66BB6A) : Colors.grey[200]!,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isOn ? Icons.pedal_bike : Icons.mic_off_outlined,
                size: 18,
                color: isOn ? Colors.green : Colors.grey[400],
              ),
              const SizedBox(width: 8),
              Text(
                isOn ? '人声唤醒中' : '点击开启语音唤醒',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isOn ? Colors.green[700] : Colors.grey[500],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.toggle_on_outlined,
                size: 24,
                color: isOn ? Colors.green : Colors.grey[300],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    WidgetRef ref,
    String petName,
    bool connected,
    bool isListening,
    WakeWordState wakeState,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '我的 $petName',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: connected ? Colors.green : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    connected ? '在线' : '离线',
                    style: TextStyle(fontSize: 12, color: connected ? Colors.green : Colors.grey),
                  ),
                  if (isListening) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.wifi_tethering, size: 12, color: Colors.green[400]),
                    const SizedBox(width: 2),
                    Text('语音待命', style: TextStyle(fontSize: 12, color: Colors.green[500])),
                  ],
                ],
              ),
            ],
          ),
          Row(
            children: [
              if (wakeState == WakeWordState.error)
                Icon(Icons.error_outline, size: 18, color: Colors.orange[300]),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => context.go('/settings'),
                color: Colors.grey[600],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(isPetActiveProvider.notifier).state = true;
                      context.go('/chat');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 4,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 20),
                        SizedBox(width: 6),
                        Text('聊天', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () => context.go('/call'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF8C94),
                      side: const BorderSide(color: Color(0xFFFF8C94), width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.phone_in_talk, size: 20),
                        SizedBox(width: 6),
                        Text('打电话', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
