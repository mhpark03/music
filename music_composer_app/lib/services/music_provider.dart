import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/note.dart';
import '../models/track.dart';
import 'audio_synthesizer.dart';

/// 음악 상태 관리 Provider
class MusicProvider extends ChangeNotifier {
  final AudioSynthesizer _synthesizer = AudioSynthesizer();
  final AudioPlayer _audioPlayer = AudioPlayer();

  MusicStyle _style = MusicStyle.electronic;
  int _bpm = 120;
  int _bars = 8;
  bool _isComposing = false;
  bool _isPlaying = false;
  String? _currentFilePath;
  String _status = 'Ready';

  // 트랙들
  late Map<String, Track> tracks;

  MusicProvider() {
    _initTracks();
  }

  void _initTracks() {
    tracks = {
      'synth': Track(
        id: 'synth',
        name: 'Synthesizer',
        instrumentType: InstrumentType.synth,
      ),
      'guitar': Track(
        id: 'guitar',
        name: 'Electric Guitar',
        instrumentType: InstrumentType.guitar,
      ),
      'bass': Track(
        id: 'bass',
        name: 'Electric Bass',
        instrumentType: InstrumentType.bass,
      ),
      'drums': Track(
        id: 'drums',
        name: 'Drum Machine',
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
  String get status => _status;
  bool get hasComposedFile => _currentFilePath != null;

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

    _status = 'Auto-generated ${_style.displayName} pattern';
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
      _status = 'No tracks with notes!';
      notifyListeners();
      return;
    }

    _isComposing = true;
    _status = 'Composing...';
    notifyListeners();

    try {
      _synthesizer.setBpm(_bpm);
      final audio = _synthesizer.composeTracks(activeTracks, totalBeats);
      final filename = 'composed_${_style.name}_${DateTime.now().millisecondsSinceEpoch}.wav';
      _currentFilePath = await _synthesizer.saveWav(audio, filename);
      _status = 'Saved: $filename';
    } catch (e) {
      _status = 'Error: $e';
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
      _status = 'Playing...';
      notifyListeners();

      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _isPlaying = false;
          _status = 'Playback finished';
          notifyListeners();
        }
      });
    } catch (e) {
      _status = 'Play error: $e';
      notifyListeners();
    }
  }

  /// 정지
  Future<void> stop() async {
    await _audioPlayer.stop();
    _isPlaying = false;
    _status = 'Stopped';
    notifyListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
