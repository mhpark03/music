import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';

/// 녹음 서비스
class RecordingService {
  final AudioRecorder _recorder = AudioRecorder();
  String? _currentRecordingPath;
  bool _isRecording = false;

  bool get isRecording => _isRecording;
  String? get currentRecordingPath => _currentRecordingPath;

  /// 마이크 권한 요청
  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// 마이크 사용 가능 여부 확인
  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  /// 녹음 시작
  Future<bool> startRecording() async {
    try {
      if (_isRecording) return false;

      // 권한 확인
      if (!await hasPermission()) {
        final granted = await requestPermission();
        if (!granted) return false;
      }

      // 저장 경로 생성
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${directory.path}/humming_$timestamp.wav';

      // 녹음 설정
      const config = RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 44100,
        numChannels: 1,
        bitRate: 128000,
      );

      // 녹음 시작
      await _recorder.start(config, path: _currentRecordingPath!);
      _isRecording = true;

      return true;
    } catch (e) {
      print('Recording error: $e');
      return false;
    }
  }

  /// 녹음 중지
  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) return null;

      final path = await _recorder.stop();
      _isRecording = false;

      // 파일 존재 확인
      if (path != null && await File(path).exists()) {
        _currentRecordingPath = path;
        return path;
      }

      return _currentRecordingPath;
    } catch (e) {
      print('Stop recording error: $e');
      _isRecording = false;
      return null;
    }
  }

  /// 녹음 취소
  Future<void> cancelRecording() async {
    if (_isRecording) {
      await _recorder.stop();
      _isRecording = false;

      // 파일 삭제
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
      _currentRecordingPath = null;
    }
  }

  /// 리소스 해제
  void dispose() {
    _recorder.dispose();
  }
}
