import 'note.dart';

/// 악기 타입
enum InstrumentType {
  synth('Synthesizer', 'Pad sounds'),
  guitar('Electric Guitar', 'Clean tone'),
  bass('Electric Bass', 'Finger bass'),
  drums('Drum Machine', 'Kick/Snare/HiHat');

  final String displayName;
  final String description;

  const InstrumentType(this.displayName, this.description);
}

/// 트랙 모델 - 한 악기의 노트들을 관리
class Track {
  final String id;
  final String name;
  final InstrumentType instrumentType;
  List<Note> notes;
  bool muted;
  double volume;

  Track({
    required this.id,
    required this.name,
    required this.instrumentType,
    List<Note>? notes,
    this.muted = false,
    this.volume = 0.8,
  }) : notes = notes ?? [];

  /// 노트 추가
  void addNote(Note note) {
    notes.add(note);
  }

  /// 노트 삭제
  void removeNote(Note note) {
    notes.remove(note);
  }

  /// 특정 위치의 노트 찾기
  Note? getNoteAt(String pitch, int beat) {
    for (var note in notes) {
      if (note.pitch == pitch &&
          note.startBeat <= beat &&
          beat < note.startBeat + note.duration) {
        return note;
      }
    }
    return null;
  }

  /// 모든 노트 삭제
  void clear() {
    notes.clear();
  }

  /// 노트 수
  int get noteCount => notes.length;

  /// 사용할 음 목록
  List<String> get availableNotes {
    return instrumentType == InstrumentType.drums ? drumNotes : melodyNotes;
  }
}

/// 음악 스타일
enum MusicStyle {
  electronic('Electronic', 128),
  rock('Rock', 120),
  pop('Pop', 110),
  jazz('Jazz', 95),
  ambient('Ambient', 70),
  ballad('Ballad', 72),
  trot('Trot', 115);

  final String displayName;
  final int defaultBpm;

  const MusicStyle(this.displayName, this.defaultBpm);
}

/// 스타일별 코드 진행
const Map<MusicStyle, List<String>> styleProgressions = {
  MusicStyle.electronic: ['C4', 'G4', 'A4', 'F4'],
  MusicStyle.rock: ['E4', 'A4', 'B4', 'E4'],
  MusicStyle.pop: ['C4', 'G4', 'A4', 'F4'],
  MusicStyle.jazz: ['C4', 'A4', 'D4', 'G4'],
  MusicStyle.ambient: ['C4', 'E4', 'F4', 'G4'],
  MusicStyle.ballad: ['G4', 'D4', 'E4', 'C4'],
  MusicStyle.trot: ['A4', 'D4', 'E4', 'A4'],
};
