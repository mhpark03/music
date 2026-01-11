import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/note.dart';
import '../models/track.dart';
import 'audio_synthesizer.dart';
import 'recording_service.dart';
import 'pitch_detector.dart';

/// 음악 상태 관리 Provider
class MusicProvider extends ChangeNotifier {
  final AudioSynthesizer _synthesizer = AudioSynthesizer();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final RecordingService _recordingService = RecordingService();
  final PitchDetector _pitchDetector = PitchDetector();

  MusicStyle _style = MusicStyle.electronic;
  int _bpm = 120;
  int _bars = 8;
  bool _isComposing = false;
  bool _isPlaying = false;
  bool _isRecording = false;
  bool _isAnalyzing = false;
  String? _currentFilePath;
  String? _recordedFilePath;
  String _status = '준비';
  List<Note> _extractedMelody = [];

  // 트랙들
  late Map<String, Track> tracks;

  MusicProvider() {
    _initTracks();
  }

  void _initTracks() {
    tracks = {
      'synth': Track(
        id: 'synth',
        name: '신디사이저',
        instrumentType: InstrumentType.synth,
      ),
      'guitar': Track(
        id: 'guitar',
        name: '일렉트릭 기타',
        instrumentType: InstrumentType.guitar,
      ),
      'bass': Track(
        id: 'bass',
        name: '일렉트릭 베이스',
        instrumentType: InstrumentType.bass,
      ),
      'drums': Track(
        id: 'drums',
        name: '드럼 머신',
        instrumentType: InstrumentType.drums,
      ),
    };
  }

  // Getters
  MusicStyle get style => _style;
  int get bpm => _bpm;
  int get bars => _bars;
  int get totalBeats => _bars * 4;
  bool get isComposing => _isComposing;
  bool get isPlaying => _isPlaying;
  bool get isRecording => _isRecording;
  bool get isAnalyzing => _isAnalyzing;
  String get status => _status;
  bool get hasComposedFile => _currentFilePath != null;
  bool get hasRecordedFile => _recordedFilePath != null;
  List<Note> get extractedMelody => _extractedMelody;

  // Setters
  void setStyle(MusicStyle newStyle) {
    _style = newStyle;
    _bpm = newStyle.defaultBpm;
    notifyListeners();
  }

  void setBpm(int newBpm) {
    _bpm = newBpm;
    notifyListeners();
  }

  void setBars(int newBars) {
    _bars = newBars;
    notifyListeners();
  }

  void setStatus(String newStatus) {
    _status = newStatus;
    notifyListeners();
  }

  /// 트랙에 노트 추가
  void addNote(String trackId, Note note) {
    tracks[trackId]?.addNote(note);
    notifyListeners();
  }

  /// 트랙에서 노트 삭제
  void removeNote(String trackId, Note note) {
    tracks[trackId]?.removeNote(note);
    notifyListeners();
  }

  /// 트랙 클리어
  void clearTrack(String trackId) {
    tracks[trackId]?.clear();
    notifyListeners();
  }

  /// 트랙 음소거 토글
  void toggleMute(String trackId) {
    final track = tracks[trackId];
    if (track != null) {
      track.muted = !track.muted;
      notifyListeners();
    }
  }

  /// 모든 트랙 자동 생성
  void autoGenerateAll() {
    final progression = styleProgressions[_style] ?? ['C4', 'G4', 'A4', 'F4'];
    final random = Random();

    for (var entry in tracks.entries) {
      final track = entry.value;
      track.clear();

      switch (track.instrumentType) {
        case InstrumentType.drums:
          _generateDrumPattern(track);
          break;
        case InstrumentType.bass:
          _generateBassLine(track, progression);
          break;
        case InstrumentType.synth:
          _generateChords(track, progression);
          break;
        case InstrumentType.guitar:
          _generateArpeggio(track, progression);
          break;
      }
    }

    _status = '${_style.displayName} 패턴 자동 생성됨';
    notifyListeners();
  }

  void _generateDrumPattern(Track track) {
    for (int beat = 0; beat < totalBeats; beat++) {
      if (_style == MusicStyle.ballad) {
        if (beat % 4 == 0) {
          track.addNote(Note(pitch: 'Kick', startBeat: beat, velocity: 0.6));
        }
        if (beat % 4 == 2) {
          track.addNote(Note(pitch: 'Snare', startBeat: beat, velocity: 0.5));
        }
        if (beat % 2 == 0) {
          track.addNote(Note(pitch: 'HiHat', startBeat: beat, velocity: 0.3));
        }
      } else if (_style == MusicStyle.trot) {
        if (beat % 2 == 0) {
          track.addNote(Note(pitch: 'Kick', startBeat: beat, velocity: 0.9));
        }
        if (beat % 2 == 1) {
          track.addNote(Note(pitch: 'Snare', startBeat: beat, velocity: 0.8));
          track.addNote(Note(pitch: 'HiHat', startBeat: beat, velocity: 0.6));
        }
      } else {
        if (beat % 4 == 0 || beat % 4 == 2) {
          track.addNote(Note(pitch: 'Kick', startBeat: beat, velocity: 0.8));
        }
        if (beat % 4 == 1 || beat % 4 == 3) {
          track.addNote(Note(pitch: 'Snare', startBeat: beat, velocity: 0.7));
        }
        if (beat % 2 == 0) {
          track.addNote(Note(pitch: 'HiHat', startBeat: beat, velocity: 0.5));
        }
      }
    }
  }

  void _generateBassLine(Track track, List<String> progression) {
    for (int bar = 0; bar < _bars; bar++) {
      final root = progression[bar % progression.length];
      final rootNote = root.replaceAll('4', '3').replaceAll('5', '4');
      for (int i = 0; i < 4; i++) {
        final beat = bar * 4 + i;
        if (i == 0) {
          track.addNote(Note(pitch: rootNote, startBeat: beat, velocity: 0.9));
        } else if (i == 2) {
          track.addNote(Note(pitch: rootNote, startBeat: beat, velocity: 0.7));
        }
      }
    }
  }

  void _generateChords(Track track, List<String> progression) {
    for (int bar = 0; bar < _bars; bar++) {
      final root = progression[bar % progression.length];
      final beat = bar * 4;
      track.addNote(Note(pitch: root, startBeat: beat, duration: 4, velocity: 0.6));

      final third = _getThird(root);
      if (third != null) {
        track.addNote(Note(pitch: third, startBeat: beat, duration: 4, velocity: 0.5));
      }

      final fifth = _getFifth(root);
      if (fifth != null) {
        track.addNote(Note(pitch: fifth, startBeat: beat, duration: 4, velocity: 0.5));
      }
    }
  }

  void _generateArpeggio(Track track, List<String> progression) {
    for (int bar = 0; bar < _bars; bar++) {
      final root = progression[bar % progression.length];
      for (int i = 0; i < 4; i++) {
        final beat = bar * 4 + i;
        if (i % 2 == 0) {
          track.addNote(Note(pitch: root, startBeat: beat, velocity: 0.7));
        }
      }
    }
  }

  String? _getThird(String root) {
    const noteMap = {'C': 'E', 'D': 'F', 'E': 'G', 'F': 'A', 'G': 'B', 'A': 'C', 'B': 'D'};
    final base = root.substring(0, root.length - 1);
    final octave = int.tryParse(root.substring(root.length - 1)) ?? 4;
    if (noteMap.containsKey(base)) {
      final newBase = noteMap[base]!;
      final newOctave = (base == 'A' || base == 'B') ? octave + 1 : octave;
      return '$newBase$newOctave';
    }
    return null;
  }

  String? _getFifth(String root) {
    const noteMap = {'C': 'G', 'D': 'A', 'E': 'B', 'F': 'C', 'G': 'D', 'A': 'E', 'B': 'F'};
    final base = root.substring(0, root.length - 1);
    final octave = int.tryParse(root.substring(root.length - 1)) ?? 4;
    if (noteMap.containsKey(base)) {
      final newBase = noteMap[base]!;
      final newOctave = (['F', 'G', 'A', 'B'].contains(base)) ? octave + 1 : octave;
      return '$newBase$newOctave';
    }
    return null;
  }

  /// 작곡 (트랙 기반)
  Future<void> compose() async {
    final activeTracks = tracks.values
        .where((t) => !t.muted && t.notes.isNotEmpty)
        .toList();

    if (activeTracks.isEmpty) {
      _status = '노트가 있는 트랙이 없습니다!';
      notifyListeners();
      return;
    }

    _isComposing = true;
    _status = '작곡 중...';
    notifyListeners();

    try {
      _synthesizer.setBpm(_bpm);
      final audio = _synthesizer.composeTracks(activeTracks, totalBeats);
      final filename = 'composed_${_style.name}_${DateTime.now().millisecondsSinceEpoch}.wav';
      _currentFilePath = await _synthesizer.saveWav(audio, filename);
      _status = '저장됨: $filename';
    } catch (e) {
      _status = '오류: $e';
    }

    _isComposing = false;
    notifyListeners();
  }

  /// 재생
  Future<void> play() async {
    if (_currentFilePath == null) return;

    try {
      await _audioPlayer.setFilePath(_currentFilePath!);
      _audioPlayer.play();
      _isPlaying = true;
      _status = '재생 중...';
      notifyListeners();

      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _isPlaying = false;
          _status = '재생 완료';
          notifyListeners();
        }
      });
    } catch (e) {
      _status = '재생 오류: $e';
      notifyListeners();
    }
  }

  /// 정지
  Future<void> stop() async {
    await _audioPlayer.stop();
    _isPlaying = false;
    _status = '정지됨';
    notifyListeners();
  }

  // ==================== 녹음 및 멜로디 추출 ====================

  /// 녹음 시작
  Future<bool> startRecording() async {
    if (_isRecording) return false;

    final success = await _recordingService.startRecording();
    if (success) {
      _isRecording = true;
      _status = '녹음 중... 멜로디를 흥얼거려 주세요!';
      notifyListeners();
    } else {
      _status = '녹음 시작 실패. 마이크 권한을 확인하세요.';
      notifyListeners();
    }
    return success;
  }

  /// 녹음 중지 및 분석
  Future<void> stopRecordingAndAnalyze() async {
    if (!_isRecording) return;

    _status = '녹음 중지 중...';
    notifyListeners();

    final path = await _recordingService.stopRecording();
    _isRecording = false;

    if (path != null) {
      _recordedFilePath = path;
      await _analyzeRecording(path);
    } else {
      _status = '녹음 실패';
      notifyListeners();
    }
  }

  /// 녹음 취소
  Future<void> cancelRecording() async {
    await _recordingService.cancelRecording();
    _isRecording = false;
    _status = '녹음 취소됨';
    notifyListeners();
  }

  /// 오디오 파일에서 멜로디 분석
  Future<void> analyzeAudioFile(String filePath) async {
    _recordedFilePath = filePath;
    await _analyzeRecording(filePath);
  }

  /// 녹음 분석
  Future<void> _analyzeRecording(String path) async {
    _isAnalyzing = true;
    _status = '멜로디 분석 중...';
    notifyListeners();

    try {
      // 피치 감지하여 멜로디 추출
      _extractedMelody = await _pitchDetector.extractMelodyFromWav(path, _bpm);

      if (_extractedMelody.isEmpty) {
        _status = '멜로디가 감지되지 않았습니다. 더 크게 또는 더 명확하게 흥얼거려 보세요.';
      } else {
        _status = '녹음에서 ${_extractedMelody.length}개의 노트 추출됨';

        // 추출된 멜로디를 신디사이저 트랙에 적용
        _applyMelodyToTrack();
      }
    } catch (e) {
      _status = '분석 오류: $e';
    }

    _isAnalyzing = false;
    notifyListeners();
  }

  /// 추출된 멜로디를 트랙에 적용하고 반주 자동 생성
  void _applyMelodyToTrack() {
    if (_extractedMelody.isEmpty) return;

    // 멜로디 길이에 맞게 마디 수 조정
    final maxBeat = _extractedMelody.map((n) => n.startBeat + n.duration).reduce(max);
    _bars = ((maxBeat + 3) ~/ 4).clamp(4, 32);

    // 기타 트랙에 멜로디 적용
    final guitarTrack = tracks['guitar']!;
    guitarTrack.clear();
    for (var note in _extractedMelody) {
      guitarTrack.addNote(note.copyWith());
    }

    // 멜로디 기반 코드 진행 생성
    final progression = _pitchDetector.generateChordProgression(_extractedMelody, _bars);

    // 다른 트랙 자동 생성
    _generateChordsFromProgression(tracks['synth']!, progression);
    _generateBassLine(tracks['bass']!, progression);
    _generateDrumPattern(tracks['drums']!);

    _status = '멜로디가 적용되고 반주가 생성되었습니다';
    notifyListeners();
  }

  /// 코드 진행 기반 코드 생성
  void _generateChordsFromProgression(Track track, List<String> progression) {
    track.clear();
    for (int bar = 0; bar < _bars; bar++) {
      final root = progression[bar % progression.length];
      final beat = bar * 4;
      track.addNote(Note(pitch: root, startBeat: beat, duration: 4, velocity: 0.5));

      final third = _getThird(root);
      if (third != null) {
        track.addNote(Note(pitch: third, startBeat: beat, duration: 4, velocity: 0.4));
      }

      final fifth = _getFifth(root);
      if (fifth != null) {
        track.addNote(Note(pitch: fifth, startBeat: beat, duration: 4, velocity: 0.4));
      }
    }
  }

  /// 멜로디만 적용 (반주 없이)
  void applyMelodyOnly() {
    if (_extractedMelody.isEmpty) return;

    // 기타 트랙에 멜로디 적용
    final guitarTrack = tracks['guitar']!;
    guitarTrack.clear();
    for (var note in _extractedMelody) {
      guitarTrack.addNote(note.copyWith());
    }

    // 다른 트랙 클리어
    tracks['synth']!.clear();
    tracks['bass']!.clear();
    tracks['drums']!.clear();

    _status = '멜로디만 적용됨';
    notifyListeners();
  }

  /// 흥얼거림 기반 전체 곡 자동 생성
  void generateFullSongFromMelody() {
    if (_extractedMelody.isEmpty) {
      _status = '생성할 멜로디가 없습니다. 먼저 녹음하세요!';
      notifyListeners();
      return;
    }

    _applyMelodyToTrack();
    _status = '흥얼거림에서 전체 곡이 생성되었습니다!';
    notifyListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _recordingService.dispose();
    super.dispose();
  }
}
