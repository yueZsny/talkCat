import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/character/providers/character_provider.dart';
import '../../features/chat/providers/chat_provider.dart';

/// 设置页面
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petName = ref.watch(petNameProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 宠物信息卡片
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8C94).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(child: Text('🐱', style: TextStyle(fontSize: 36))),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      petName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '陪伴宠物 · v1.0.0',
                      style: TextStyle(color: Colors.grey[400], fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // 设置选项
          _buildSectionTitle(context, '宠物设置'),
          const SizedBox(height: 8),
          _buildSettingCard(context, [
            _SettingItem(
              icon: Icons.edit_outlined,
              title: '修改宠物名字',
              subtitle: '当前：$petName',
              onTap: () => _showRenameDialog(context, ref),
            ),
            _SettingItem(
              icon: Icons.face_4_outlined,
              title: '宠物形象',
              subtitle: '默认猫咪',
              onTap: () {},
              enabled: false,
            ),
            _SettingItem(
              icon: Icons.volume_up_outlined,
              title: '语音类型',
              subtitle: '默认女声 (Phase 2 开启)',
              onTap: () {},
              enabled: false,
            ),
          ]),
          const SizedBox(height: 20),
          _buildSectionTitle(context, '对话设置'),
          const SizedBox(height: 8),
          _buildSettingCard(context, [
            _SettingItem(
              icon: Icons.delete_outline,
              title: '清空聊天记录',
              subtitle: '删除所有对话内容',
              onTap: () => _showClearConfirmDialog(context, ref),
              isDestructive: true,
            ),
          ]),
          const SizedBox(height: 20),
          _buildSectionTitle(context, '关于'),
          const SizedBox(height: 8),
          _buildSettingCard(context, [
            const _SettingItem(
              icon: Icons.info_outline,
              title: '版本',
              subtitle: 'v1.0.0 (Phase 1)',
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey[500],
        ),
      ),
    );
  }

  Widget _buildSettingCard(BuildContext context, List<_SettingItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Column(
            children: [
              if (index > 0)
                Divider(height: 1, indent: 56, color: Colors.grey[100]),
              _buildSettingItem(context, item),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSettingItem(BuildContext context, _SettingItem item) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: item.enabled ? item.onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              item.icon,
              color: item.isDestructive
                  ? Colors.red[400]
                  : (item.enabled ? Colors.grey[700] : Colors.grey[350]),
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: item.isDestructive
                          ? Colors.red[400]
                          : (item.enabled ? Colors.grey[800] : Colors.grey[400]),
                    ),
                  ),
                  if (item.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
                  ],
                ],
              ),
            ),
            if (item.enabled)
              Icon(Icons.chevron_right, color: Colors.grey[300], size: 20),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('修改宠物名字'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '输入新的名字',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                // 目前 petName 是 Provider，暂不支持修改
                // TODO: 后续接入实际存储
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('已修改为 ${controller.text.trim()}')),
                );
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showClearConfirmDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清空聊天记录'),
        content: const Text('确定要删除所有对话记录吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              ref.read(chatProvider.notifier).clear();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('聊天记录已清空')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('确定清空'),
          ),
        ],
      ),
    );
  }
}

class _SettingItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool enabled;
  final bool isDestructive;

  const _SettingItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.enabled = true,
    this.isDestructive = false,
  });
}
