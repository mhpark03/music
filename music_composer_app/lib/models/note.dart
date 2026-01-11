/// 음표 모델
class Note {
  String pitch; // 예: 'C4', 'E4', 'Kick', 'Snare'
  int startBeat; // 시작 비트 (0부터)
  int duration; // 비트 단위 길이
  double velocity; // 음량 (0.0 ~ 1.0)

  Note({
    required this.pitch,
    required this.startBeat,
    this.duration = 1,
    this.velocity = 0.8,
  });

  /// 주파수 반환 (Hz)
  double get frequency {
    return noteFrequencies[pitch] ?? 440.0;
  }

  /// 복사본 생성
  Note copyWith({
    String? pitch,
    int? startBeat,
    int? duration,
    double? velocity,
  }) {
    return Note(
      pitch: pitch ?? this.pitch,
      startBeat: startBeat ?? this.startBeat,
      duration: duration ?? this.duration,
      velocity: velocity ?? this.velocity,
    );
  }

  @override
  String toString() => 'Note($pitch, beat=$startBeat, dur=$duration)';
}

/// 음계별 주파수 맵
const Map<String, double> noteFrequencies = {
  'C2': 65.41, 'C#2': 69.30, 'D2': 73.42, 'D#2': 77.78,
  'E2': 82.41, 'F2': 87.31, 'F#2': 92.50, 'G2': 98.00,
  'G#2': 103.83, 'A2': 110.00, 'A#2': 116.54, 'B2': 123.47,
  'C3': 130.81, 'C#3': 138.59, 'D3': 146.83, 'D#3': 155.56,
  'E3': 164.81, 'F3': 174.61, 'F#3': 185.00, 'G3': 196.00,
  'G#3': 207.65, 'A3': 220.00, 'A#3': 233.08, 'B3': 246.94,
  'C4': 261.63, 'C#4': 277.18, 'D4': 293.66, 'D#4': 311.13,
  'E4': 329.63, 'F4': 349.23, 'F#4': 369.99, 'G4': 392.00,
  'G#4': 415.30, 'A4': 440.00, 'A#4': 466.16, 'B4': 493.88,
  'C5': 523.25, 'C#5': 554.37, 'D5': 587.33, 'D#5': 622.25,
  'E5': 659.25, 'F5': 698.46, 'F#5': 739.99, 'G5': 783.99,
  'G#5': 830.61, 'A5': 880.00, 'A#5': 932.33, 'B5': 987.77,
};

/// 표시할 음 목록 (멜로디 악기용)
const List<String> melodyNotes = [
  'C3', 'D3', 'E3', 'F3', 'G3', 'A3', 'B3',
  'C4', 'D4', 'E4', 'F4', 'G4', 'A4', 'B4',
  'C5', 'D5', 'E5', 'F5', 'G5', 'A5', 'B5',
];

/// 드럼 노트
const List<String> drumNotes = ['Kick', 'Snare', 'HiHat'];
