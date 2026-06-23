import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/call_models.dart';

/// 通话管理器
class CallNotifier extends StateNotifier<CallState> {
  Timer? _callTimer;
  int _elapsed = 0;

  CallNotifier() : super(CallState());

  /// 发起通话
  Future<void> initiateCall(Contact contact, {CallTriggerType type = CallTriggerType.userRequest}) async {
    state = CallState(
      activeCall: ActiveCall(
        callId: DateTime.now().millisecondsSinceEpoch.toString(),
        contactName: contact.name,
        contactPhone: contact.phone,
        status: CallStatus.initiating,
        triggerType: type,
      ),
    );

    // 模拟响铃
    await Future.delayed(const Duration(seconds: 2));
    if (state.activeCall == null) return;

    state = state.copyWith(activeCall: state.activeCall!..status = CallStatus.ringing);

    // 模拟接通
    await Future.delayed(const Duration(seconds: 3));
    if (state.activeCall == null) return;

    _startCallTimer();
    state = state.copyWith(activeCall: state.activeCall!..status = CallStatus.connected);
  }

  /// 接听来电
  void answerCall() {
    if (state.activeCall == null) return;
    _startCallTimer();
    state = state.copyWith(activeCall: state.activeCall!..status = CallStatus.connected);
  }

  /// 挂断通话
  void hangup() {
    _callTimer?.cancel();

    if (state.activeCall != null) {
      final call = state.activeCall!;
      call.status = CallStatus.completed;
      call.durationSeconds = _elapsed;

      // 保存到通话记录
      final log = CallLog(
        id: call.callId,
        contactName: call.contactName,
        contactPhone: call.contactPhone,
        direction: CallDirection.outgoing,
        status: CallStatus.completed,
        durationSeconds: _elapsed,
        startedAt: DateTime.now().subtract(Duration(seconds: _elapsed)),
        endedAt: DateTime.now(),
      );

      state = state.copyWith(
        activeCall: null,
        recentCalls: [log, ...state.recentCalls],
      );
    }

    _elapsed = 0;
  }

  /// 切换静音
  void toggleMute() {
    if (state.activeCall == null) return;
    final call = state.activeCall!;
    call.isMuted = !call.isMuted;
    state = state.copyWith(activeCall: call);
  }

  /// 切换扬声器
  void toggleSpeaker() {
    if (state.activeCall == null) return;
    final call = state.activeCall!;
    call.isSpeakerOn = !call.isSpeakerOn;
    state = state.copyWith(activeCall: call);
  }

  void _startCallTimer() {
    _elapsed = 0;
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsed++;
      if (state.activeCall != null) {
        state = state.copyWith(activeCall: state.activeCall!..durationSeconds = _elapsed);
      }
    });
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    super.dispose();
  }
}

/// 通话状态
class CallState {
  final ActiveCall? activeCall;
  final List<CallLog> recentCalls;

  const CallState({this.activeCall, this.recentCalls = const []});

  /// 是否有活跃通话
  bool get hasActiveCall => activeCall != null;

  CallState copyWith({ActiveCall? activeCall, List<CallLog>? recentCalls}) {
    return CallState(
      activeCall: activeCall ?? this.activeCall,
      recentCalls: recentCalls ?? this.recentCalls,
    );
  }
}

final callProvider = StateNotifierProvider<CallNotifier, CallState>((ref) {
  return CallNotifier();
});

/// 联系人列表
final contactsProvider = StateProvider<List<Contact>>((ref) {
  return [
    const Contact(id: '1', name: '妈妈', phone: '13800138001', relationship: 'family', isEmergency: true),
    const Contact(id: '2', name: '爸爸', phone: '13800138002', relationship: 'family'),
    const Contact(id: '3', name: '闺蜜小美', phone: '13800138003', relationship: 'friend'),
    const Contact(id: '4', name: '张医生', phone: '13800138004', relationship: 'doctor', isEmergency: true),
  ];
});
