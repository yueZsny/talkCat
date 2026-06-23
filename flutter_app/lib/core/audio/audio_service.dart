/// 音频服务抽象 — Phase 2 实现
/// 负责：音频采集、播放、VAD 检测
class AudioService {
  // TODO: Phase 2 集成音频录制与播放

  /// 开始录音
  Future<void> startRecording() async {
    // TODO: 使用 record 插件采集音频
  }

  /// 停止录音并返回音频数据
  Future<List<int>> stopRecording() async {
    // TODO: 返回 PCM/WAV 数据
    return [];
  }

  /// 播放音频（TTS 输出）
  Future<void> playAudio(String url) async {
    // TODO: 使用 audioplayers / just_audio
  }

  /// 停止播放
  Future<void> stopPlayback() async {
    // TODO: 停止播放
  }

  /// VAD 检测 — 判断用户是否说完
  bool isSilence(List<int> audioData) {
    // TODO: 集成 Silero VAD
    return false;
  }

  void dispose() {
    // 清理资源
  }
}
