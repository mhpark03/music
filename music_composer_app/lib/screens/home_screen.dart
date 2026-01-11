import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/track.dart';
import '../services/music_provider.dart';
import 'score_editor_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Electric Music Composer'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<MusicProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 스타일 선택
                _buildStyleSection(context, provider),
                const SizedBox(height: 16),

                // 트랙 섹션
                _buildTracksSection(context, provider),
                const SizedBox(height: 16),

                // BPM 설정
                _buildBpmSection(provider),
                const SizedBox(height: 16),

                // 마디 수 설정
                _buildBarsSection(provider),
                const SizedBox(height: 24),

                // 버튼들
                _buildButtonsSection(context, provider),
                const SizedBox(height: 16),

                // 상태 표시
                _buildStatusSection(provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStyleSection(BuildContext context, MusicProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Style',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: MusicStyle.values.map((style) {
                final isSelected = provider.style == style;
                return ChoiceChip(
                  label: Text(style.displayName),
                  selected: isSelected,
                  onSelected: (_) => provider.setStyle(style),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTracksSection(BuildContext context, MusicProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tracks & Score Editor',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...provider.tracks.entries.map((entry) {
              final track = entry.value;
              return _buildTrackRow(context, provider, track);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackRow(BuildContext context, MusicProvider provider, Track track) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // 음소거 체크박스
          Checkbox(
            value: !track.muted,
            onChanged: (_) => provider.toggleMute(track.id),
          ),
          // 트랙 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${track.instrumentType.description} - ${track.noteCount} notes',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          // 악보 편집 버튼
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ScoreEditorScreen(trackId: track.id),
                ),
              );
            },
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Widget _buildBpmSection(MusicProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('BPM'),
                Text(
                  '${provider.bpm}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            Slider(
              value: provider.bpm.toDouble(),
              min: 60,
              max: 180,
              divisions: 120,
              label: '${provider.bpm}',
              onChanged: (value) => provider.setBpm(value.toInt()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarsSection(MusicProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bars'),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [4, 8, 16].map((bars) {
                return ChoiceChip(
                  label: Text('$bars bars'),
                  selected: provider.bars == bars,
                  onSelected: (_) => provider.setBars(bars),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonsSection(BuildContext context, MusicProvider provider) {
    return Column(
      children: [
        // Auto Generate 버튼
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: provider.autoGenerateAll,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Auto Generate All'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Compose, Play, Stop 버튼
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: provider.isComposing ? null : provider.compose,
                icon: provider.isComposing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.music_note),
                label: const Text('Compose'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: provider.hasComposedFile && !provider.isPlaying
                    ? provider.play
                    : null,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Play'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: provider.isPlaying ? provider.stop : null,
                icon: const Icon(Icons.stop),
                label: const Text('Stop'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusSection(MusicProvider provider) {
    return Card(
      color: Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              provider.isPlaying
                  ? Icons.volume_up
                  : provider.isComposing
                      ? Icons.hourglass_top
                      : Icons.info_outline,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                provider.status,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
