/// 通话状态
enum CallStatus {
  idle,
  initiating,  // 正在发起
  ringing,     // 正在响铃
  connected,   // 通话中
  completed,   // 已结束
  missed,      // 未接
  failed,      // 失败
}

/// 通话方向
enum CallDirection { outgoing, incoming }

/// 触发类型
enum CallTriggerType {
  userRequest,   // 用户指令
  scheduled,     // 定时任务
  autoCheckin,   // AI 主动关怀
  emergency,     // 紧急情况
}

/// 联系人
class Contact {
  final String id;
  final String name;
  final String phone;
  final String relationship;
  final bool isEmergency;

  const Contact({
    required this.id,
    required this.name,
    required this.phone,
    this.relationship = 'friend',
    this.isEmergency = false,
  });

  String get avatar => name.isNotEmpty ? name[0] : '?';
}

/// 通话记录
class CallLog {
  final String id;
  final String contactName;
  final String contactPhone;
  final CallDirection direction;
  final CallStatus status;
  final int durationSeconds;
  final CallTriggerType triggerType;
  final String? summary;
  final DateTime startedAt;
  final DateTime? endedAt;

  const CallLog({
    required this.id,
    required this.contactName,
    required this.contactPhone,
    required this.direction,
    required this.status,
    this.durationSeconds = 0,
    this.triggerType = CallTriggerType.userRequest,
    this.summary,
    required this.startedAt,
    this.endedAt,
  });

  String get durationString {
    if (durationSeconds < 60) return '${durationSeconds}秒';
    final min = durationSeconds ~/ 60;
    final sec = durationSeconds % 60;
    return '${min}分${sec}秒';
  }
}

/// 活跃通话会话
class ActiveCall {
  final String callId;
  final String contactName;
  final String contactPhone;
  CallStatus status;
  int durationSeconds;
  final CallTriggerType triggerType;
  bool isMuted;
  bool isSpeakerOn;

  ActiveCall({
    required this.callId,
    required this.contactName,
    required this.contactPhone,
    this.status = CallStatus.initiating,
    this.durationSeconds = 0,
    this.triggerType = CallTriggerType.userRequest,
    this.isMuted = false,
    this.isSpeakerOn = false,
  });
}
