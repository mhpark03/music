import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import '../models/note.dart';

/// 피치 감지 서비스 - 오디오에서 멜로디 추출
class PitchDetector {
  static const int sampleRate = 44100;

  /// WAV 파일에서 멜로디 추출
  Future<List<Note>> extractMelodyFromWav(String filePath, int bpm) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File not found: $filePath');
    }

    final bytes = await file.readAsBytes();
    final samples = _parseWavFile(bytes);

    if (samples.isEmpty) {
      throw Exception('Could not parse audio file');
    }

    return _detectPitches(samples, bpm);
  }

  /// WAV 파일 파싱하여 샘플 데이터 추출
  List<double> _parseWavFile(Uint8List bytes) {
    if (bytes.length < 44) return [];

    // WAV 헤더 확인
    final riff = String.fromCharCodes(bytes.sublist(0, 4));
    if (riff != 'RIFF') return [];

    final wave = String.fromCharCodes(bytes.sublist(8, 12));
    if (wave != 'WAVE') return [];

    // fmt 청크 찾기
    int pos = 12;
    int audioFormat = 1;
    int numChannels = 1;
    int bitsPerSample = 16;
    int dataStart = 44;
    int dataSize = bytes.length - 44;

    while (pos < bytes.length - 8) {
      final chunkId = String.fromCharCodes(bytes.sublist(pos, pos + 4));
      final chunkSize = _readInt32(bytes, pos + 4);

      if (chunkId == 'fmt ') {
        audioFormat = _readInt16(bytes, pos + 8);
        numChannels = _readInt16(bytes, pos + 10);
        bitsPerSample = _readInt16(bytes, pos + 22);
      } else if (chunkId == 'data') {
        dataStart = pos + 8;
        dataSize = chunkSize;
        break;
      }

      pos += 8 + chunkSize;
    }

    // PCM만 지원
    if (audioFormat != 1) return [];

    // 샘플 추출
    final samples = <double>[];
    final bytesPerSample = bitsPerSample ~/ 8;

    for (int i = dataStart; i < dataStart + dataSize; i += bytesPerSample * numChannels) {
      if (i + bytesPerSample > bytes.length) break;

      int sample;
      if (bitsPerSample == 16) {
        sample = _readInt16Signed(bytes, i);
        samples.add(sample / 32768.0);
      } else if (bitsPerSample == 8) {
        sample = bytes[i] - 128;
        samples.add(sample / 128.0);
      }
    }

    return samples;
  }

  int _readInt16(Uint8List bytes, int offset) {
    return bytes[offset] | (bytes[offset + 1] << 8);
  }

  int _readInt16Signed(Uint8List bytes, int offset) {
    int value = bytes[offset] | (bytes[offset + 1] << 8);
    if (value >= 32768) value -= 65536;
    return value;
  }

  int _readInt32(Uint8List bytes, int offset) {
    return bytes[offset] |
        (bytes[offset + 1] << 8) |
        (bytes[offset + 2] << 16) |
        (bytes[offset + 3] << 24);
  }

  /// 피치 감지하여 노트 목록 생성
  List<Note> _detectPitches(List<double> samples, int bpm) {
    final notes = <Note>[];
    final beatDuration = 60.0 / bpm;
    final samplesPerBeat = (sampleRate * beatDuration).toInt();

    // 각 비트 구간에서 주요 주파수 찾기
    int beat = 0;
    for (int i = 0; i < samples.length; i += samplesPerBeat ~/ 2) {
      final end = min(i + samplesPerBeat, samples.length);
      final chunk = samples.sublist(i, end);

      // RMS로 음량 확인
      final rms = _calculateRMS(chunk);
      if (rms < 0.02) {
        // 묵음 구간
        beat++;
        continue;
      }

      // 주파수 감지 (자기상관 방법)
      final frequency = _detectFrequency(chunk);

      if (frequency > 0) {
        final pitch = _frequencyToNote(frequency);
        if (pitch != null) {
          // 이전 노트와 같으면 duration 증가
          if (notes.isNotEmpty &&
              notes.last.pitch == pitch &&
              notes.last.startBeat + notes.last.duration == beat) {
            notes.last.duration++;
          } else {
            notes.add(Note(
              pitch: pitch,
              startBeat: beat,
              duration: 1,
              velocity: min(1.0, rms * 5),
            ));
          }
        }
      }
      beat++;
    }

    return _cleanupNotes(notes);
  }

  /// RMS 계산
  double _calculateRMS(List<double> samples) {
    if (samples.isEmpty) return 0;
    double sum = 0;
    for (var sample in samples) {
      sum += sample * sample;
    }
    return sqrt(sum / samples.length);
  }

  /// 자기상관을 이용한 주파수 감지
  double _detectFrequency(List<double> samples) {
    if (samples.length < 256) return 0;

    // 사람 음성 범위: 80Hz ~ 1000Hz
    final minPeriod = (sampleRate / 1000).toInt(); // 1000Hz
    final maxPeriod = (sampleRate / 80).toInt();   // 80Hz

    double maxCorrelation = 0;
    int bestPeriod = 0;

    // 자기상관 계산
    for (int period = minPeriod; period < min(maxPeriod, samples.length ~/ 2); period++) {
      double correlation = 0;
      for (int i = 0; i < samples.length - period; i++) {
        correlation += samples[i] * samples[i + period];
      }
      correlation /= (samples.length - period);

      if (correlation > maxCorrelation) {
        maxCorrelation = correlation;
        bestPeriod = period;
      }
    }

    if (bestPeriod == 0 || maxCorrelation < 0.1) return 0;

    return sampleRate / bestPeriod;
  }

  /// 주파수를 음표 이름으로 변환
  String? _frequencyToNote(double frequency) {
    if (frequency < 65 || frequency > 1000) return null;

    // A4 = 440Hz 기준
    final semitones = 12 * log(frequency / 440) / log(2);
    final midiNote = (69 + semitones).round();

    if (midiNote < 36 || midiNote > 84) return null;

    final noteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    final noteName = noteNames[midiNote % 12];
    final octave = (midiNote ~/ 12) - 1;

    return '$noteName$octave';
  }

  /// 노트 정리 (너무 짧은 노트 제거, 간격 정리)
  List<Note> _cleanupNotes(List<Note> notes) {
    if (notes.isEmpty) return notes;

    // 너무 짧은 노트 제거
    final cleaned = notes.where((n) => n.duration >= 1).toList();

    // 시작 비트 정규화 (0부터 시작)
    if (cleaned.isNotEmpty) {
      final offset = cleaned.first.startBeat;
      for (var note in cleaned) {
        note.startBeat -= offset;
      }
    }

    return cleaned;
  }

  /// 멜로디에서 키(조) 추정
  String detectKey(List<Note> melody) {
    if (melody.isEmpty) return 'C';

    // 음표 빈도 계산
    final noteCount = <String, int>{};
    for (var note in melody) {
      final baseName = note.pitch.replaceAll(RegExp(r'[0-9]'), '');
      noteCount[baseName] = (noteCount[baseName] ?? 0) + note.duration;
    }

    // 가장 많이 나온 음을 키로 추정
    String mostCommon = 'C';
    int maxCount = 0;
    noteCount.forEach((note, count) {
      if (count > maxCount) {
        maxCount = count;
        mostCommon = note;
      }
    });

    return mostCommon;
  }

  /// 멜로디 기반 코드 진행 생성
  List<String> generateChordProgression(List<Note> melody, int bars) {
    if (melody.isEmpty) {
      return ['C4', 'G4', 'A4', 'F4'];
    }

    final key = detectKey(melody);
    final progression = <String>[];

    // 간단한 코드 진행 규칙
    final majorProgressions = {
      'C': ['C4', 'F4', 'G4', 'C4'],
      'D': ['D4', 'G4', 'A4', 'D4'],
      'E': ['E4', 'A4', 'B4', 'E4'],
      'F': ['F4', 'A#4', 'C4', 'F4'],
      'G': ['G4', 'C4', 'D4', 'G4'],
      'A': ['A4', 'D4', 'E4', 'A4'],
      'B': ['B4', 'E4', 'F#4', 'B4'],
    };

    final baseProgression = majorProgressions[key] ?? majorProgressions['C']!;

    for (int i = 0; i < bars; i++) {
      progression.add(baseProgression[i % baseProgression.length]);
    }

    return progression;
  }
}
