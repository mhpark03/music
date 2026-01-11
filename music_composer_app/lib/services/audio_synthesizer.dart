import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import '../models/note.dart';
import '../models/track.dart';

/// 오디오 합성기
class AudioSynthesizer {
  static const int sampleRate = 44100;

  int bpm;
  double get beatDuration => 60.0 / bpm;

  AudioSynthesizer({this.bpm = 120});

  /// BPM 설정
  void setBpm(int newBpm) {
    bpm = newBpm;
  }

  /// 사인파 생성
  Float64List _sineWave(double freq, double duration, double velocity) {
    final samples = (sampleRate * duration).toInt();
    final wave = Float64List(samples);
    for (int i = 0; i < samples; i++) {
      final t = i / sampleRate;
      wave[i] = sin(2 * pi * freq * t) * velocity;
    }
    return _applyEnvelope(wave, duration);
  }

  /// 패드 사운드 (신디사이저)
  Float64List _padSound(double freq, double duration, double velocity) {
    final samples = (sampleRate * duration).toInt();
    final wave = Float64List(samples);
    for (int i = 0; i < samples; i++) {
      final t = i / sampleRate;
      wave[i] = (sin(2 * pi * freq * t) * 0.5 +
              sin(2 * pi * freq * 2 * t) * 0.25 +
              sin(2 * pi * freq * 0.5 * t) * 0.25) *
          velocity;
    }
    return _applyEnvelope(wave, duration, attack: 0.3, release: 0.4);
  }

  /// 클린 기타 톤
  Float64List _cleanGuitar(double freq, double duration, double velocity) {
    final samples = (sampleRate * duration).toInt();
    final wave = Float64List(samples);
    for (int i = 0; i < samples; i++) {
      final t = i / sampleRate;
      wave[i] = (sin(2 * pi * freq * t) * 0.6 +
              sin(2 * pi * freq * 2 * t) * 0.25 +
              sin(2 * pi * freq * 3 * t) * 0.1 +
              sin(2 * pi * freq * 4 * t) * 0.05) *
          velocity;
    }
    return _applyEnvelope(wave, duration, attack: 0.01, release: 0.2);
  }

  /// 핑거 베이스
  Float64List _fingerBass(double freq, double duration, double velocity) {
    final samples = (sampleRate * duration).toInt();
    final wave = Float64List(samples);
    for (int i = 0; i < samples; i++) {
      final t = i / sampleRate;
      wave[i] = (sin(2 * pi * freq * t) * 0.7 +
              sin(2 * pi * freq * 2 * t) * 0.2 +
              sin(2 * pi * freq * 3 * t) * 0.1) *
          velocity;
    }
    return _applyEnvelope(wave, duration, attack: 0.02, release: 0.15);
  }

  /// 킥 드럼
  Float64List _kick(double velocity) {
    const duration = 0.3;
    final samples = (sampleRate * duration).toInt();
    final wave = Float64List(samples);
    for (int i = 0; i < samples; i++) {
      final t = i / sampleRate;
      final freqEnvelope = 150 * exp(-t * 20) + 40;
      double phase = 0;
      for (int j = 0; j <= i; j++) {
        final tj = j / sampleRate;
        phase += 2 * pi * (150 * exp(-tj * 20) + 40) / sampleRate;
      }
      wave[i] = sin(phase) * exp(-t * 10) * velocity;
    }
    return wave;
  }

  /// 스네어 드럼
  Float64List _snare(double velocity) {
    const duration = 0.2;
    final samples = (sampleRate * duration).toInt();
    final wave = Float64List(samples);
    final random = Random();
    for (int i = 0; i < samples; i++) {
      final t = i / sampleRate;
      final tone = sin(2 * pi * 200 * t) * exp(-t * 20);
      final noise = (random.nextDouble() * 2 - 1) * exp(-t * 15) * 0.5;
      wave[i] = (tone + noise) * velocity * 0.8;
    }
    return wave;
  }

  /// 하이햇
  Float64List _hihat(double velocity) {
    const duration = 0.1;
    final samples = (sampleRate * duration).toInt();
    final wave = Float64List(samples);
    final random = Random();
    for (int i = 0; i < samples; i++) {
      final t = i / sampleRate;
      wave[i] = (random.nextDouble() * 2 - 1) * exp(-t * 30) * velocity * 0.4;
    }
    return wave;
  }

  /// 엔벨로프 적용
  Float64List _applyEnvelope(Float64List wave, double duration,
      {double attack = 0.05, double release = 0.1}) {
    final samples = wave.length;
    final attackSamples = (attack * sampleRate).toInt();
    final releaseSamples = (release * sampleRate).toInt();

    for (int i = 0; i < attackSamples && i < samples; i++) {
      wave[i] *= i / attackSamples;
    }
    for (int i = 0; i < releaseSamples && (samples - 1 - i) >= 0; i++) {
      wave[samples - 1 - i] *= i / releaseSamples;
    }
    return wave;
  }

  /// 트랙을 오디오로 렌더링
  Float64List renderTrack(Track track, int totalBeats) {
    final totalDuration = totalBeats * beatDuration;
    final totalSamples = (sampleRate * totalDuration).toInt();
    final audio = Float64List(totalSamples);

    for (var note in track.notes) {
      final startSample = (note.startBeat * beatDuration * sampleRate).toInt();
      final duration = note.duration * beatDuration;

      Float64List wave;
      switch (track.instrumentType) {
        case InstrumentType.synth:
          wave = _padSound(note.frequency, duration, note.velocity);
          break;
        case InstrumentType.guitar:
          wave = _cleanGuitar(note.frequency, duration, note.velocity);
          break;
        case InstrumentType.bass:
          wave = _fingerBass(note.frequency / 2, duration, note.velocity);
          break;
        case InstrumentType.drums:
          if (note.pitch == 'Kick') {
            wave = _kick(note.velocity);
          } else if (note.pitch == 'Snare') {
            wave = _snare(note.velocity);
          } else if (note.pitch == 'HiHat') {
            wave = _hihat(note.velocity);
          } else {
            continue;
          }
          break;
      }

      final endSample = min(startSample + wave.length, totalSamples);
      for (int i = startSample; i < endSample; i++) {
        audio[i] += wave[i - startSample] * track.volume;
      }
    }

    return audio;
  }

  /// 모든 트랙을 합쳐서 최종 오디오 생성
  Float64List composeTracks(List<Track> tracks, int totalBeats) {
    final totalDuration = totalBeats * beatDuration;
    final totalSamples = (sampleRate * totalDuration).toInt();
    final mix = Float64List(totalSamples);

    for (var track in tracks) {
      if (!track.muted && track.notes.isNotEmpty) {
        final trackAudio = renderTrack(track, totalBeats);
        for (int i = 0; i < totalSamples && i < trackAudio.length; i++) {
          mix[i] += trackAudio[i];
        }
      }
    }

    // 노멀라이즈
    double maxVal = 0;
    for (var sample in mix) {
      if (sample.abs() > maxVal) maxVal = sample.abs();
    }
    if (maxVal > 0) {
      for (int i = 0; i < mix.length; i++) {
        mix[i] = mix[i] / maxVal * 0.9;
      }
    }

    return mix;
  }

  /// WAV 파일로 저장
  Future<String> saveWav(Float64List audio, String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$filename';

    final file = File(filePath);
    final bytes = _createWavBytes(audio);
    await file.writeAsBytes(bytes);

    return filePath;
  }

  /// WAV 바이트 생성
  Uint8List _createWavBytes(Float64List audio) {
    final numSamples = audio.length;
    final byteRate = sampleRate * 2; // 16-bit mono
    final dataSize = numSamples * 2;
    final fileSize = 36 + dataSize;

    final buffer = ByteData(44 + dataSize);

    // RIFF header
    buffer.setUint8(0, 0x52); // 'R'
    buffer.setUint8(1, 0x49); // 'I'
    buffer.setUint8(2, 0x46); // 'F'
    buffer.setUint8(3, 0x46); // 'F'
    buffer.setUint32(4, fileSize, Endian.little);
    buffer.setUint8(8, 0x57); // 'W'
    buffer.setUint8(9, 0x41); // 'A'
    buffer.setUint8(10, 0x56); // 'V'
    buffer.setUint8(11, 0x45); // 'E'

    // fmt chunk
    buffer.setUint8(12, 0x66); // 'f'
    buffer.setUint8(13, 0x6D); // 'm'
    buffer.setUint8(14, 0x74); // 't'
    buffer.setUint8(15, 0x20); // ' '
    buffer.setUint32(16, 16, Endian.little); // chunk size
    buffer.setUint16(20, 1, Endian.little); // PCM
    buffer.setUint16(22, 1, Endian.little); // mono
    buffer.setUint32(24, sampleRate, Endian.little);
    buffer.setUint32(28, byteRate, Endian.little);
    buffer.setUint16(32, 2, Endian.little); // block align
    buffer.setUint16(34, 16, Endian.little); // bits per sample

    // data chunk
    buffer.setUint8(36, 0x64); // 'd'
    buffer.setUint8(37, 0x61); // 'a'
    buffer.setUint8(38, 0x74); // 't'
    buffer.setUint8(39, 0x61); // 'a'
    buffer.setUint32(40, dataSize, Endian.little);

    // audio data
    for (int i = 0; i < numSamples; i++) {
      final sample = (audio[i] * 32767).toInt().clamp(-32768, 32767);
      buffer.setInt16(44 + i * 2, sample, Endian.little);
    }

    return buffer.buffer.asUint8List();
  }
}
