import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../models/track.dart';
import '../services/music_provider.dart';
import 'score_editor_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('전기 악기 음악 작곡기'),
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
                // 녹음 섹션 (새로 추가)
                _buildRecordingSection(context, provider),
                const SizedBox(height: 16),

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

  Widget _buildRecordingSection(BuildContext context, MusicProvider provider) {
    return Card(
      color: provider.isRecording ? Colors.red[50] : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.mic,
                  color: provider.isRecording ? Colors.red : null,
                ),
                const SizedBox(width: 8),
                Text(
                  '흥얼거림으로 작곡',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '흥얼거림을 녹음하면 자동으로 곡을 만들어 드립니다!',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // 녹음 버튼
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: provider.isRecording || provider.isAnalyzing
                        ? null
                        : provider.startRecording,
                    icon: const Icon(Icons.fiber_manual_record),
                    label: const Text('녹음'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[400],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 녹음 중지 버튼
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: provider.isRecording
                        ? provider.stopRecordingAndAnalyze
                        : null,
                    icon: provider.isAnalyzing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.stop),
                    label: Text(provider.isAnalyzing ? '분석중...' : '정지'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[400],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 파일 선택 버튼
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: provider.isRecording || provider.isAnalyzing
                        ? null
                        : () => _pickAudioFile(context, provider),
                    icon: const Icon(Icons.folder_open),
                    label: const Text('파일'),
                  ),
                ),
              ],
            ),
            if (provider.extractedMelody.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${provider.extractedMelody.length}개 노트 추출됨',
                        style: const TextStyle(color: Colors.green),
                      ),
                    ),
                    TextButton(
                      onPressed: provider.generateFullSongFromMelody,
                      child: const Text('다시 생성'),
                    ),
                  ],
                ),
              ),
            ],
            if (provider.isRecording) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  '지금 멜로디를 흥얼거려 주세요...',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickAudioFile(BuildContext context, MusicProvider provider) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final path = result.files.first.path;
        if (path != null) {
          await provider.analyzeAudioFile(path);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('파일 선택 오류: $e')),
        );
      }
    }
  }

  Widget _buildStyleSection(BuildContext context, MusicProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '스타일',
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
              '트랙 & 악보 편집',
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
                  '${track.instrumentType.description} - ${track.noteCount}개 노트',
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
            label: const Text('편집'),
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
            const Text('마디'),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [4, 8, 16].map((bars) {
                return ChoiceChip(
                  label: Text('$bars마디'),
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
            label: const Text('전체 자동 생성'),
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
                label: const Text('작곡'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: provider.hasComposedFile && !provider.isPlaying
                    ? provider.play
                    : null,
                icon: const Icon(Icons.play_arrow),
                label: const Text('재생'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: provider.isPlaying ? provider.stop : null,
                icon: const Icon(Icons.stop),
                label: const Text('정지'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusSection(MusicProvider provider) {
    IconData statusIcon;
    Color? iconColor;

    if (provider.isRecording) {
      statusIcon = Icons.mic;
      iconColor = Colors.red;
    } else if (provider.isAnalyzing) {
      statusIcon = Icons.analytics;
      iconColor = Colors.orange;
    } else if (provider.isPlaying) {
      statusIcon = Icons.volume_up;
      iconColor = Colors.green;
    } else if (provider.isComposing) {
      statusIcon = Icons.hourglass_top;
      iconColor = Colors.blue;
    } else {
      statusIcon = Icons.info_outline;
      iconColor = null;
    }

    return Card(
      color: Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(statusIcon, size: 20, color: iconColor),
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
