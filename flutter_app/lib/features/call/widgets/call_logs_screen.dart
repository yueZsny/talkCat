import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/call_provider.dart';
import '../models/call_models.dart';

/// 通话记录页面
class CallLogsScreen extends ConsumerWidget {
  const CallLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(callProvider);
    final logs = state.recentCalls;

    return Scaffold(
      appBar: AppBar(
        title: const Text('通话记录'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: logs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.phone_missed_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    '暂无通话记录',
                    style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '让宠物帮你打个电话吧～',
                    style: TextStyle(fontSize: 13, color: Colors.grey[300]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                return _buildCallLogItem(context, log);
              },
            ),
    );
  }

  Widget _buildCallLogItem(BuildContext context, CallLog log) {
    final isOutgoing = log.direction == CallDirection.outgoing;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: const Color(0xFFFF8C94).withValues(alpha: 0.15),
          child: Text(
            log.contactName[0],
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF8C94),
            ),
          ),
        ),
        title: Text(log.contactName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Row(
          children: [
            Icon(
              isOutgoing ? Icons.call_made : Icons.call_received,
              size: 12,
              color: log.status == CallStatus.missed ? Colors.red : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              log.durationString,
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            if (log.summary != null) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  log.summary!,
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        trailing: _buildStatusIcon(log.status),
      ),
    );
  }

  Widget _buildStatusIcon(CallStatus status) {
    switch (status) {
      case CallStatus.completed:
        return Icon(Icons.check_circle_outline, color: Colors.green[400], size: 20);
      case CallStatus.missed:
        return Icon(Icons.cancel_outlined, color: Colors.red[400], size: 20);
      case CallStatus.failed:
        return Icon(Icons.error_outline, color: Colors.orange[400], size: 20);
      default:
        return Icon(Icons.info_outline, color: Colors.grey[400], size: 20);
    }
  }
}
