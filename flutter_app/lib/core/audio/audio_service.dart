import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';

/// 音频服务 — 录制和播放语音
class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  /// 是否正在录音
  bool _isRecording = false;
  bool get isRecording => _isRecording;

  /// 是否正在播放
  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  /// 开始录音
  Future<bool> startRecording({int maxDurationSec = 30}) async {
    if (kIsWeb) return false;
    try {
      // 检查麦克风权限
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        print('[Audio] 无麦克风权限');
        return false;
      }

      // 开始录音到临时文件 (WAV 格式)
      final path = '${Directory.systemTemp.path}/pet_voice_${DateTime.now().millisecondsSinceEpoch}.wav';
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,  // 16kHz 适合 ASR
          numChannels: 1,
          bitRate: 256000,
        ),
        path: path,
      );

      _isRecording = true;

      // 自动停止计时
      if (maxDurationSec > 0) {
        Timer(Duration(seconds: maxDurationSec), () async {
          if (_isRecording) {
            await stopRecording();
          }
        });
      }

      return true;
    } catch (e) {
      print('[Audio] 开始录音失败: $e');
      return false;
    }
  }

  /// 停止录音并返回音频文件路径
  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) return null;
      _isRecording = false;

      final path = await _recorder.stop();
      return path;
    } catch (e) {
      print('[Audio] 停止录音失败: $e');
      return null;
    }
  }

  /// 获取录音振幅 (0.0 ~ 1.0，用于可视化)
  Stream<double> getAmplitudeStream() {
    return _recorder.onAmplitudeChanged(
      const Duration(milliseconds: 100),
    ).map((amplitude) {
      // 归一化到 0.0~1.0
      final current = amplitude.current;
      return (current / 160).clamp(0.0, 1.0);
    });
  }

  /// 播放音频文件
  Future<void> playFile(String path) async {
    try {
      _isPlaying = true;
      await _player.play(DeviceFileSource(path));
      // 等待播放完成
      await _player.onPlayerComplete.first;
      _isPlaying = false;
    } catch (e) {
      print('[Audio] 播放文件失败: $e');
      _isPlaying = false;
    }
  }

  /// 播放音频字节数据 (从后端获取的 MP3)
  Future<void> playBytes(List<int> bytes) async {
    if (kIsWeb) return;
    try {
      _isPlaying = true;
      // 写入临时文件再播放
      final tempPath = '${Directory.systemTemp.path}/pet_tts_${DateTime.now().millisecondsSinceEpoch}.mp3';
      final file = File(tempPath);
      await file.writeAsBytes(bytes);
      await _player.play(DeviceFileSource(tempPath));
      await _player.onPlayerComplete.first;
      _isPlaying = false;
    } catch (e) {
      print('[Audio] 播放字节失败: $e');
      _isPlaying = false;
    }
  }

  /// 停止播放
  Future<void> stopPlayback() async {
    await _player.stop();
    _isPlaying = false;
  }

  /// 获取当前播放位置 (用于口型同步)
  Stream<Duration> get onPositionChanged => _player.onPositionChanged;

  /// 获取音频总时长
  Future<Duration?> getDuration() async {
    final result = await _player.getDuration();
    return result;
  }

  void dispose() {
    _recorder.dispose();
    _player.dispose();
  }
}
