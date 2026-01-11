import 'package:flutter/material.dart';
import '../models/note.dart';
import '../models/track.dart';

class PianoRoll extends StatefulWidget {
  final Track track;
  final int totalBeats;
  final double velocity;
  final Function(Note) onNoteAdded;
  final Function(Note) onNoteRemoved;

  const PianoRoll({
    super.key,
    required this.track,
    required this.totalBeats,
    required this.velocity,
    required this.onNoteAdded,
    required this.onNoteRemoved,
  });

  @override
  State<PianoRoll> createState() => _PianoRollState();
}

class _PianoRollState extends State<PianoRoll> {
  static const double cellWidth = 40;
  static const double cellHeight = 30;
  static const double labelWidth = 60;

  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  List<String> get availableNotes => widget.track.availableNotes.reversed.toList();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            // 음 레이블 (왼쪽 고정)
            SizedBox(
              width: labelWidth,
              child: _buildNoteLabels(),
            ),
            // 그리드 영역 (스크롤 가능)
            Expanded(
              child: _buildGrid(constraints),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNoteLabels() {
    return SingleChildScrollView(
      controller: _verticalController,
      child: Column(
        children: availableNotes.map((note) {
          final isBlackKey = note.contains('#');
          return Container(
            width: labelWidth,
            height: cellHeight,
            decoration: BoxDecoration(
              color: isBlackKey ? Colors.grey[800] : Colors.grey[300],
              border: Border.all(color: Colors.grey[400]!, width: 0.5),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              note,
              style: TextStyle(
                color: isBlackKey ? Colors.white : Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGrid(BoxConstraints constraints) {
    final gridWidth = widget.totalBeats * cellWidth;
    final gridHeight = availableNotes.length * cellHeight;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: _horizontalController,
      child: SingleChildScrollView(
        controller: _verticalController,
        child: SizedBox(
          width: gridWidth,
          height: gridHeight,
          child: Stack(
            children: [
              // 그리드 배경
              CustomPaint(
                size: Size(gridWidth, gridHeight),
                painter: GridPainter(
                  totalBeats: widget.totalBeats,
                  numNotes: availableNotes.length,
                  cellWidth: cellWidth,
                  cellHeight: cellHeight,
                  notes: availableNotes,
                ),
              ),
              // 노트들
              ..._buildNotes(),
              // 터치 입력 처리
              GestureDetector(
                onTapUp: (details) => _handleTap(details.localPosition),
                onLongPressStart: (details) => _handleLongPress(details.localPosition),
                child: Container(color: Colors.transparent),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildNotes() {
    return widget.track.notes.map((note) {
      final noteIndex = availableNotes.indexOf(note.pitch);
      if (noteIndex == -1) return const SizedBox.shrink();

      final left = note.startBeat * cellWidth;
      final top = noteIndex * cellHeight;
      final width = note.duration * cellWidth;

      return Positioned(
        left: left + 2,
        top: top + 2,
        child: GestureDetector(
          onLongPress: () => widget.onNoteRemoved(note),
          child: Container(
            width: width - 4,
            height: cellHeight - 4,
            decoration: BoxDecoration(
              color: _getNoteColor(note.velocity),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 2,
                  offset: const Offset(1, 1),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              note.pitch,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Color _getNoteColor(double velocity) {
    final intensity = (100 + velocity * 155).toInt();
    switch (widget.track.instrumentType) {
      case InstrumentType.synth:
        return Color.fromRGBO(intensity, 96, intensity, 1);
      case InstrumentType.guitar:
        return Color.fromRGBO(intensity, intensity, 96, 1);
      case InstrumentType.bass:
        return Color.fromRGBO(96, intensity, 96, 1);
      case InstrumentType.drums:
        return Color.fromRGBO(intensity, 96, 96, 1);
    }
  }

  void _handleTap(Offset position) {
    final beat = (position.dx / cellWidth).floor();
    final noteIndex = (position.dy / cellHeight).floor();

    if (beat < 0 || beat >= widget.totalBeats) return;
    if (noteIndex < 0 || noteIndex >= availableNotes.length) return;

    final pitch = availableNotes[noteIndex];

    // 이미 노트가 있는지 확인
    final existingNote = widget.track.getNoteAt(pitch, beat);
    if (existingNote == null) {
      final newNote = Note(
        pitch: pitch,
        startBeat: beat,
        duration: 1,
        velocity: widget.velocity,
      );
      widget.onNoteAdded(newNote);
    }
  }

  void _handleLongPress(Offset position) {
    final beat = (position.dx / cellWidth).floor();
    final noteIndex = (position.dy / cellHeight).floor();

    if (noteIndex < 0 || noteIndex >= availableNotes.length) return;

    final pitch = availableNotes[noteIndex];
    final note = widget.track.getNoteAt(pitch, beat);
    if (note != null) {
      widget.onNoteRemoved(note);
    }
  }
}

class GridPainter extends CustomPainter {
  final int totalBeats;
  final int numNotes;
  final double cellWidth;
  final double cellHeight;
  final List<String> notes;

  GridPainter({
    required this.totalBeats,
    required this.numNotes,
    required this.cellWidth,
    required this.cellHeight,
    required this.notes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint();
    final linePaint = Paint()
      ..color = Colors.grey[600]!
      ..strokeWidth = 0.5;
    final barLinePaint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 2;

    // 배경 그리기
    for (int i = 0; i < numNotes; i++) {
      final isBlackKey = notes[i].contains('#');
      backgroundPaint.color = isBlackKey ? Colors.grey[850]! : Colors.grey[900]!;
      canvas.drawRect(
        Rect.fromLTWH(0, i * cellHeight, size.width, cellHeight),
        backgroundPaint,
      );
    }

    // 수평선 그리기
    for (int i = 0; i <= numNotes; i++) {
      canvas.drawLine(
        Offset(0, i * cellHeight),
        Offset(size.width, i * cellHeight),
        linePaint,
      );
    }

    // 수직선 그리기
    for (int i = 0; i <= totalBeats; i++) {
      final isBarLine = i % 4 == 0;
      canvas.drawLine(
        Offset(i * cellWidth, 0),
        Offset(i * cellWidth, size.height),
        isBarLine ? barLinePaint : linePaint,
      );

      // 마디 번호
      if (isBarLine && i < totalBeats) {
        final barNum = (i ~/ 4) + 1;
        final textPainter = TextPainter(
          text: TextSpan(
            text: '$barNum',
            style: TextStyle(color: Colors.grey[500], fontSize: 10),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(i * cellWidth + 4, 4));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
