import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../models/track.dart';
import '../services/music_provider.dart';
import '../widgets/piano_roll.dart';

class ScoreEditorScreen extends StatefulWidget {
  final String trackId;

  const ScoreEditorScreen({super.key, required this.trackId});

  @override
  State<ScoreEditorScreen> createState() => _ScoreEditorScreenState();
}

class _ScoreEditorScreenState extends State<ScoreEditorScreen> {
  double _velocity = 0.8;

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, provider, child) {
        final track = provider.tracks[widget.trackId];
        if (track == null) {
          return const Scaffold(
            body: Center(child: Text('Track not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('${track.name} - Score Editor'),
            backgroundColor: _getTrackColor(track.instrumentType).withOpacity(0.3),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_sweep),
                tooltip: 'Clear All',
                onPressed: () => _showClearDialog(context, provider),
              ),
              IconButton(
                icon: const Icon(Icons.auto_fix_high),
                tooltip: 'Auto Generate',
                onPressed: () => _autoGenerate(provider, track),
              ),
            ],
          ),
          body: Column(
            children: [
              // 툴바
              _buildToolbar(context),

              // 피아노 롤
              Expanded(
                child: PianoRoll(
                  track: track,
                  totalBeats: provider.totalBeats,
                  velocity: _velocity,
                  onNoteAdded: (note) => provider.addNote(widget.trackId, note),
                  onNoteRemoved: (note) => provider.removeNote(widget.trackId, note),
                ),
              ),

              // 하단 범례
              _buildLegend(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[200],
      child: Row(
        children: [
          const Text('Velocity: '),
          Expanded(
            child: Slider(
              value: _velocity,
              min: 0.1,
              max: 1.0,
              divisions: 9,
              label: _velocity.toStringAsFixed(1),
              onChanged: (value) {
                setState(() {
                  _velocity = value;
                });
              },
            ),
          ),
          Text(
            _velocity.toStringAsFixed(1),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey[100],
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.touch_app, size: 16),
          SizedBox(width: 4),
          Text('Tap: Add note'),
          SizedBox(width: 16),
          Icon(Icons.close, size: 16),
          SizedBox(width: 4),
          Text('Long press: Delete'),
        ],
      ),
    );
  }

  Color _getTrackColor(InstrumentType type) {
    switch (type) {
      case InstrumentType.synth:
        return Colors.purple;
      case InstrumentType.guitar:
        return Colors.amber;
      case InstrumentType.bass:
        return Colors.green;
      case InstrumentType.drums:
        return Colors.red;
    }
  }

  void _showClearDialog(BuildContext context, MusicProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notes'),
        content: const Text('Are you sure you want to delete all notes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.clearTrack(widget.trackId);
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _autoGenerate(MusicProvider provider, Track track) {
    provider.clearTrack(widget.trackId);

    final progression = styleProgressions[provider.style] ?? ['C4', 'G4', 'A4', 'F4'];
    final totalBeats = provider.totalBeats;

    switch (track.instrumentType) {
      case InstrumentType.drums:
        for (int beat = 0; beat < totalBeats; beat++) {
          if (beat % 4 == 0 || beat % 4 == 2) {
            provider.addNote(widget.trackId, Note(pitch: 'Kick', startBeat: beat, velocity: 0.8));
          }
          if (beat % 4 == 1 || beat % 4 == 3) {
            provider.addNote(widget.trackId, Note(pitch: 'Snare', startBeat: beat, velocity: 0.7));
          }
          if (beat % 2 == 0) {
            provider.addNote(widget.trackId, Note(pitch: 'HiHat', startBeat: beat, velocity: 0.5));
          }
        }
        break;

      case InstrumentType.bass:
        for (int bar = 0; bar < provider.bars; bar++) {
          final root = progression[bar % progression.length];
          final rootNote = root.replaceAll('4', '3').replaceAll('5', '4');
          provider.addNote(widget.trackId, Note(pitch: rootNote, startBeat: bar * 4, velocity: 0.9));
          provider.addNote(widget.trackId, Note(pitch: rootNote, startBeat: bar * 4 + 2, velocity: 0.7));
        }
        break;

      case InstrumentType.synth:
        for (int bar = 0; bar < provider.bars; bar++) {
          final root = progression[bar % progression.length];
          provider.addNote(widget.trackId, Note(pitch: root, startBeat: bar * 4, duration: 4, velocity: 0.6));
        }
        break;

      case InstrumentType.guitar:
        for (int bar = 0; bar < provider.bars; bar++) {
          final root = progression[bar % progression.length];
          for (int i = 0; i < 4; i += 2) {
            provider.addNote(widget.trackId, Note(pitch: root, startBeat: bar * 4 + i, velocity: 0.7));
          }
        }
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pattern generated!')),
    );
  }
}
