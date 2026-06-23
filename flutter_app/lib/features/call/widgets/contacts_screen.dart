import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/call_provider.dart';
import '../models/call_models.dart';

/// 联系人列表 — 选择要拨打的联系人
class ContactsScreen extends ConsumerWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contacts = ref.watch(contactsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('打电话'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.go('/call-logs'),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: contacts.length + 1, // +1 for header
        itemBuilder: (context, index) {
          if (index == 0) return _buildHeader(context);

          final contact = contacts[index - 1];
          return _buildContactItem(context, ref, contact);
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        '选择要呼叫的联系人',
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[500],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildContactItem(BuildContext context, WidgetRef ref, Contact contact) {
    // 紧急联系分组
    final isEmergency = contact.isEmergency;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isEmergency
            ? const BorderSide(color: Color(0xFFFF6B81), width: 1.5)
            : BorderSide.none,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: isEmergency
              ? const Color(0xFFFF6B81).withValues(alpha: 0.15)
              : const Color(0xFFFF8C94).withValues(alpha: 0.15),
          child: Text(
            contact.avatar,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isEmergency ? const Color(0xFFFF6B81) : const Color(0xFFFF8C94),
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              contact.name,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            if (isEmergency) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '紧急',
                  style: TextStyle(fontSize: 10, color: Colors.red[400], fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          contact.phone,
          style: TextStyle(color: Colors.grey[400], fontSize: 13),
        ),
        trailing: const Icon(Icons.phone_in_talk, color: Color(0xFFFF8C94)),
        onTap: () {
          // 跳转到通话界面
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CallScreenWrapper(contact: contact),
            ),
          );
        },
      ),
    );
  }
}

/// 通话界面包装（提供独立的 Provider 作用域）
class CallScreenWrapper extends ConsumerWidget {
  final Contact contact;

  const CallScreenWrapper({super.key, required this.contact});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _CallScreenBody(contact: contact);
  }
}

class _CallScreenBody extends ConsumerStatefulWidget {
  final Contact contact;
  const _CallScreenBody({required this.contact});

  @override
  ConsumerState<_CallScreenBody> createState() => _CallScreenBodyState();
}

class _CallScreenBodyState extends ConsumerState<_CallScreenBody> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            ref.read(callProvider.notifier).hangup();
            context.pop();
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 拨号中...
            _buildAvatar(),
            const SizedBox(height: 24),
            Text(
              widget.contact.name,
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '正在呼叫...',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 48),
            // 挂断
            Material(
              color: Colors.red,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () {
                  context.pop();
                },
                child: Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  child: const Icon(Icons.call_end, color: Colors.white, size: 32),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8C94), Color(0xFFFF6B81)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF8C94).withValues(alpha: 0.4),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Center(
        child: Text(
          widget.contact.avatar,
          style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
