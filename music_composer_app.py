"""
전기 악기 음악 작곡 앱
Electric Instrument Music Composer App

GUI를 통해 스타일과 악기를 선택하여 음악을 작곡합니다.
"""

import tkinter as tk
from tkinter import ttk, messagebox
import numpy as np
from scipy.io import wavfile
import random
import threading
import os
import winsound

# 샘플링 레이트
SAMPLE_RATE = 44100

# 음계 주파수 (Hz)
NOTE_FREQUENCIES = {
    'C3': 130.81, 'C#3': 138.59, 'D3': 146.83, 'D#3': 155.56,
    'E3': 164.81, 'F3': 174.61, 'F#3': 185.00, 'G3': 196.00,
    'G#3': 207.65, 'A3': 220.00, 'A#3': 233.08, 'B3': 246.94,
    'C4': 261.63, 'C#4': 277.18, 'D4': 293.66, 'D#4': 311.13,
    'E4': 329.63, 'F4': 349.23, 'F#4': 369.99, 'G4': 392.00,
    'G#4': 415.30, 'A4': 440.00, 'A#4': 466.16, 'B4': 493.88,
    'C5': 523.25, 'D5': 587.33, 'E5': 659.25, 'F5': 698.46,
    'G5': 783.99, 'A5': 880.00, 'B5': 987.77,
}

# 코드 패턴
CHORD_PATTERNS = {
    'major': [0, 4, 7],
    'minor': [0, 3, 7],
    'seventh': [0, 4, 7, 10],
    'power': [0, 7, 12],
}

# 코드 진행
PROGRESSIONS = {
    'electronic': ['C4', 'G4', 'A4', 'F4'],
    'rock': ['E4', 'A4', 'B4', 'E4'],
    'pop': ['C4', 'G4', 'A4', 'F4'],
    'jazz': ['C4', 'A4', 'D4', 'G4'],
    'ambient': ['C4', 'E4', 'F4', 'G4'],
    'ballad': ['G4', 'D4', 'E4', 'C4'],      # 발라드: 감성적인 진행
    'trot': ['A4', 'D4', 'E4', 'A4'],        # 트로트: 마이너 진행
}

# 스타일별 기본 BPM
STYLE_BPM = {
    'electronic': 128,
    'rock': 120,
    'pop': 110,
    'jazz': 95,
    'ambient': 70,
    'ballad': 72,       # 발라드: 느린 템포
    'trot': 115,        # 트로트: 중간 템포
}


class Synthesizer:
    """신디사이저"""

    @staticmethod
    def sine_wave(freq, duration, velocity=1.0):
        t = np.linspace(0, duration, int(SAMPLE_RATE * duration), False)
        wave = np.sin(2 * np.pi * freq * t) * velocity
        return Synthesizer._apply_envelope(wave, duration)

    @staticmethod
    def square_wave(freq, duration, velocity=1.0):
        t = np.linspace(0, duration, int(SAMPLE_RATE * duration), False)
        wave = np.sign(np.sin(2 * np.pi * freq * t)) * velocity * 0.5
        return Synthesizer._apply_envelope(wave, duration)

    @staticmethod
    def sawtooth_wave(freq, duration, velocity=1.0):
        t = np.linspace(0, duration, int(SAMPLE_RATE * duration), False)
        wave = 2 * (t * freq - np.floor(0.5 + t * freq)) * velocity * 0.5
        return Synthesizer._apply_envelope(wave, duration)

    @staticmethod
    def pad_sound(freq, duration, velocity=1.0):
        t = np.linspace(0, duration, int(SAMPLE_RATE * duration), False)
        wave = (np.sin(2 * np.pi * freq * t) * 0.5 +
                np.sin(2 * np.pi * freq * 2 * t) * 0.25 +
                np.sin(2 * np.pi * freq * 0.5 * t) * 0.25)
        wave *= velocity
        return Synthesizer._apply_envelope(wave, duration, attack=0.3, release=0.4)

    @staticmethod
    def _apply_envelope(wave, duration, attack=0.05, release=0.1):
        samples = len(wave)
        attack_samples = int(attack * SAMPLE_RATE)
        release_samples = int(release * SAMPLE_RATE)
        envelope = np.ones(samples)
        if attack_samples > 0 and attack_samples < samples:
            envelope[:attack_samples] = np.linspace(0, 1, attack_samples)
        if release_samples > 0 and release_samples < samples:
            envelope[-release_samples:] = np.linspace(1, 0, release_samples)
        return wave * envelope


class ElectricGuitar:
    """일렉트릭 기타"""

    @staticmethod
    def clean_tone(freq, duration, velocity=1.0):
        t = np.linspace(0, duration, int(SAMPLE_RATE * duration), False)
        wave = (np.sin(2 * np.pi * freq * t) * 0.6 +
                np.sin(2 * np.pi * freq * 2 * t) * 0.25 +
                np.sin(2 * np.pi * freq * 3 * t) * 0.1 +
                np.sin(2 * np.pi * freq * 4 * t) * 0.05)
        wave *= velocity
        return Synthesizer._apply_envelope(wave, duration, attack=0.01, release=0.2)

    @staticmethod
    def distortion(freq, duration, velocity=1.0):
        t = np.linspace(0, duration, int(SAMPLE_RATE * duration), False)
        wave = np.sin(2 * np.pi * freq * t)
        wave = np.clip(wave * 3, -0.8, 0.8)
        wave += np.sin(2 * np.pi * freq * 2 * t) * 0.3
        wave = np.clip(wave, -1, 1) * velocity * 0.7
        return Synthesizer._apply_envelope(wave, duration, attack=0.01, release=0.15)


class ElectricBass:
    """일렉트릭 베이스"""

    @staticmethod
    def finger_bass(freq, duration, velocity=1.0):
        t = np.linspace(0, duration, int(SAMPLE_RATE * duration), False)
        wave = (np.sin(2 * np.pi * freq * t) * 0.7 +
                np.sin(2 * np.pi * freq * 2 * t) * 0.2 +
                np.sin(2 * np.pi * freq * 3 * t) * 0.1)
        wave *= velocity
        return Synthesizer._apply_envelope(wave, duration, attack=0.02, release=0.15)

    @staticmethod
    def slap_bass(freq, duration, velocity=1.0):
        t = np.linspace(0, duration, int(SAMPLE_RATE * duration), False)
        wave = (np.sin(2 * np.pi * freq * t) * 0.5 +
                np.sin(2 * np.pi * freq * 2 * t) * 0.3 +
                np.sin(2 * np.pi * freq * 4 * t) * 0.2)
        attack_samples = int(0.02 * SAMPLE_RATE)
        if attack_samples < len(wave):
            wave[:attack_samples] *= np.linspace(2, 1, attack_samples)
        wave = np.clip(wave, -1, 1) * velocity
        return Synthesizer._apply_envelope(wave, duration, attack=0.005, release=0.1)


class DrumMachine:
    """드럼 머신"""

    @staticmethod
    def kick(duration=0.3, velocity=1.0):
        t = np.linspace(0, duration, int(SAMPLE_RATE * duration), False)
        freq_envelope = 150 * np.exp(-t * 20) + 40
        phase = np.cumsum(2 * np.pi * freq_envelope / SAMPLE_RATE)
        wave = np.sin(phase) * np.exp(-t * 10) * velocity
        return wave

    @staticmethod
    def snare(duration=0.2, velocity=1.0):
        t = np.linspace(0, duration, int(SAMPLE_RATE * duration), False)
        tone = np.sin(2 * np.pi * 200 * t) * np.exp(-t * 20)
        noise = np.random.uniform(-1, 1, len(t)) * np.exp(-t * 15) * 0.5
        wave = (tone + noise) * velocity * 0.8
        return wave

    @staticmethod
    def hihat(duration=0.1, velocity=1.0):
        t = np.linspace(0, duration, int(SAMPLE_RATE * duration), False)
        noise = np.random.uniform(-1, 1, len(t))
        wave = noise * np.exp(-t * 30) * velocity * 0.4
        return wave

    @staticmethod
    def clap(duration=0.15, velocity=1.0):
        t = np.linspace(0, duration, int(SAMPLE_RATE * duration), False)
        noise = np.random.uniform(-1, 1, len(t))
        envelope = np.zeros(len(t))
        for i in range(4):
            start = int(i * 0.01 * SAMPLE_RATE)
            if start < len(envelope):
                envelope[start:] += np.exp(-np.arange(len(envelope) - start) / SAMPLE_RATE * 50)
        wave = noise * envelope * np.exp(-t * 20) * velocity * 0.5
        return wave


class MusicComposer:
    """음악 작곡기"""

    def __init__(self, bpm=120):
        self.bpm = bpm
        self.beat_duration = 60.0 / bpm
        self.synth = Synthesizer()
        self.guitar = ElectricGuitar()
        self.bass = ElectricBass()
        self.drums = DrumMachine()

    def set_bpm(self, bpm):
        self.bpm = bpm
        self.beat_duration = 60.0 / bpm

    def get_frequency(self, note):
        return NOTE_FREQUENCIES.get(note, 440.0)

    def generate_synth_track(self, progression, bars, synth_type='pad'):
        """신디사이저 트랙 생성"""
        bar_duration = self.beat_duration * 4
        track = []

        for bar in range(bars):
            root = progression[bar % len(progression)]
            root_freq = self.get_frequency(root)

            chord_wave = np.zeros(int(SAMPLE_RATE * bar_duration))
            for semitones in CHORD_PATTERNS['major']:
                freq = root_freq * (2 ** (semitones / 12))
                if synth_type == 'pad':
                    note_wave = self.synth.pad_sound(freq, bar_duration, 0.4)
                elif synth_type == 'square':
                    note_wave = self.synth.square_wave(freq, bar_duration, 0.3)
                else:
                    note_wave = self.synth.sawtooth_wave(freq, bar_duration, 0.3)

                if len(note_wave) < len(chord_wave):
                    note_wave = np.pad(note_wave, (0, len(chord_wave) - len(note_wave)))
                chord_wave += note_wave[:len(chord_wave)]

            track.append(chord_wave / 3)

        return np.concatenate(track)

    def generate_guitar_track(self, progression, bars, guitar_type='clean'):
        """기타 트랙 생성"""
        bar_duration = self.beat_duration * 4
        track = []

        for bar in range(bars):
            root = progression[bar % len(progression)]
            root_freq = self.get_frequency(root)

            chord_wave = np.zeros(int(SAMPLE_RATE * bar_duration))
            pattern = CHORD_PATTERNS['power'] if guitar_type == 'distortion' else CHORD_PATTERNS['major']

            for semitones in pattern:
                freq = root_freq * (2 ** (semitones / 12))
                if guitar_type == 'distortion':
                    note_wave = self.guitar.distortion(freq, bar_duration, 0.4)
                else:
                    note_wave = self.guitar.clean_tone(freq, bar_duration, 0.4)

                if len(note_wave) < len(chord_wave):
                    note_wave = np.pad(note_wave, (0, len(chord_wave) - len(note_wave)))
                chord_wave += note_wave[:len(chord_wave)]

            track.append(chord_wave / len(pattern))

        return np.concatenate(track)

    def generate_bass_track(self, progression, bars, bass_type='finger'):
        """베이스 트랙 생성"""
        track = []

        for bar in range(bars):
            root = progression[bar % len(progression)]
            root_lower = root.replace('4', '3').replace('5', '4')
            freq = self.get_frequency(root_lower)

            pattern_freqs = [freq, freq, freq * 1.5, freq]
            for i, f in enumerate(pattern_freqs):
                velocity = 0.9 if i == 0 else 0.7
                if bass_type == 'slap':
                    wave = self.bass.slap_bass(f, self.beat_duration, velocity)
                else:
                    wave = self.bass.finger_bass(f, self.beat_duration, velocity)
                track.append(wave)

        return np.concatenate(track)

    def generate_drum_track(self, bars, style='basic'):
        """드럼 트랙 생성"""
        beat_samples = int(SAMPLE_RATE * self.beat_duration)
        bar_samples = beat_samples * 4
        total_samples = bar_samples * bars
        drums = np.zeros(total_samples)

        for bar in range(bars):
            bar_start = bar * bar_samples

            for beat in range(4):
                beat_start = bar_start + beat * beat_samples

                if style == 'ballad':
                    # 발라드: 부드러운 드럼, 1박에만 킥, 3박에 스네어
                    if beat == 0:
                        kick = self.drums.kick(velocity=0.6)
                        end_idx = min(beat_start + len(kick), total_samples)
                        drums[beat_start:end_idx] += kick[:end_idx - beat_start]
                    if beat == 2:
                        snare = self.drums.snare(velocity=0.5)
                        end_idx = min(beat_start + len(snare), total_samples)
                        drums[beat_start:end_idx] += snare[:end_idx - beat_start]
                    # 부드러운 하이햇
                    hihat = self.drums.hihat(velocity=0.3)
                    end_idx = min(beat_start + len(hihat), total_samples)
                    drums[beat_start:end_idx] += hihat[:end_idx - beat_start]

                elif style == 'trot':
                    # 트로트: 쿵짝쿵짝 뽕짝 리듬
                    if beat in [0, 2]:  # 쿵 (킥)
                        kick = self.drums.kick(velocity=0.9)
                        end_idx = min(beat_start + len(kick), total_samples)
                        drums[beat_start:end_idx] += kick[:end_idx - beat_start]
                    if beat in [1, 3]:  # 짝 (스네어 + 하이햇)
                        snare = self.drums.snare(velocity=0.8)
                        end_idx = min(beat_start + len(snare), total_samples)
                        drums[beat_start:end_idx] += snare[:end_idx - beat_start]
                        hihat = self.drums.hihat(velocity=0.7)
                        end_idx = min(beat_start + len(hihat), total_samples)
                        drums[beat_start:end_idx] += hihat[:end_idx - beat_start]
                    # 오프비트에 하이햇 추가 (경쾌함)
                    offbeat_start = beat_start + beat_samples // 2
                    if offbeat_start < total_samples:
                        hihat = self.drums.hihat(velocity=0.4)
                        end_idx = min(offbeat_start + len(hihat), total_samples)
                        drums[offbeat_start:end_idx] += hihat[:end_idx - offbeat_start]

                else:
                    # 기본 패턴
                    if beat in [0, 2]:
                        kick = self.drums.kick()
                        end_idx = min(beat_start + len(kick), total_samples)
                        drums[beat_start:end_idx] += kick[:end_idx - beat_start]
                    if beat in [1, 3]:
                        snare = self.drums.snare()
                        end_idx = min(beat_start + len(snare), total_samples)
                        drums[beat_start:end_idx] += snare[:end_idx - beat_start]
                    for eighth in range(2):
                        hh_start = beat_start + eighth * (beat_samples // 2)
                        velocity = 0.6 if eighth == 0 else 0.4
                        hihat = self.drums.hihat(velocity=velocity)
                        end_idx = min(hh_start + len(hihat), total_samples)
                        drums[hh_start:end_idx] += hihat[:end_idx - hh_start]

        return drums

    def compose(self, style, instruments, bars=8):
        """작곡"""
        progression = PROGRESSIONS.get(style, PROGRESSIONS['electronic'])
        bar_duration = self.beat_duration * 4
        total_samples = int(SAMPLE_RATE * bar_duration * bars)

        tracks = []
        volumes = []

        # 각 악기 트랙 생성
        if instruments.get('synth', False):
            if style in ['ambient', 'electronic', 'ballad']:
                synth_type = 'pad'  # 발라드: 부드러운 패드
            elif style == 'trot':
                synth_type = 'square'  # 트로트: 밝은 사각파
            else:
                synth_type = 'sawtooth'
            track = self.generate_synth_track(progression, bars, synth_type)
            vol = 0.35 if style == 'ballad' else 0.3
            tracks.append(track)
            volumes.append(vol)

        if instruments.get('guitar', False):
            if style == 'rock':
                guitar_type = 'distortion'
            else:
                guitar_type = 'clean'  # 발라드, 트로트: 클린 기타
            track = self.generate_guitar_track(progression, bars, guitar_type)
            vol = 0.35 if style == 'ballad' else 0.3
            tracks.append(track)
            volumes.append(vol)

        if instruments.get('bass', False):
            bass_type = 'slap' if style == 'jazz' else 'finger'
            track = self.generate_bass_track(progression, bars, bass_type)
            volumes.append(0.25)
            tracks.append(track)

        if instruments.get('drums', False):
            track = self.generate_drum_track(bars, style)  # 스타일 전달
            vol = 0.25 if style == 'ballad' else 0.35  # 발라드: 드럼 볼륨 낮춤
            tracks.append(track)
            volumes.append(vol)

        if not tracks:
            return np.zeros(total_samples)

        # 믹싱
        def pad_to_length(arr, length):
            if len(arr) < length:
                return np.pad(arr, (0, length - len(arr)))
            return arr[:length]

        mix = np.zeros(total_samples)
        for track, vol in zip(tracks, volumes):
            mix += pad_to_length(track, total_samples) * vol

        # 노멀라이즈
        max_val = np.max(np.abs(mix))
        if max_val > 0:
            mix = mix / max_val * 0.9

        return mix

    def save_wav(self, audio, filename):
        audio_int = (audio * 32767).astype(np.int16)
        wavfile.write(filename, SAMPLE_RATE, audio_int)
        return filename


class MusicComposerApp:
    """음악 작곡 앱 GUI"""

    def __init__(self, root):
        self.root = root
        self.root.title("Electric Music Composer")
        self.root.geometry("500x600")
        self.root.resizable(False, False)

        self.composer = MusicComposer()
        self.current_file = None
        self.is_composing = False

        self.setup_ui()

    def setup_ui(self):
        """UI 설정"""
        # 메인 프레임
        main_frame = ttk.Frame(self.root, padding="20")
        main_frame.pack(fill=tk.BOTH, expand=True)

        # 제목
        title_label = ttk.Label(main_frame, text="Electric Music Composer",
                                 font=('Helvetica', 18, 'bold'))
        title_label.pack(pady=(0, 20))

        # 스타일 선택
        style_frame = ttk.LabelFrame(main_frame, text="Style", padding="10")
        style_frame.pack(fill=tk.X, pady=10)

        self.style_var = tk.StringVar(value="electronic")
        styles = [
            ("Electronic", "electronic"),
            ("Rock", "rock"),
            ("Pop", "pop"),
            ("Jazz", "jazz"),
            ("Ambient", "ambient"),
            ("Ballad", "ballad"),
            ("Trot", "trot"),
        ]

        style_inner = ttk.Frame(style_frame)
        style_inner.pack()

        for i, (text, value) in enumerate(styles):
            rb = ttk.Radiobutton(style_inner, text=text, value=value,
                                  variable=self.style_var,
                                  command=self.on_style_change)
            row = 0 if i < 4 else 1  # 4개씩 2줄 배치
            col = i if i < 4 else i - 4
            rb.grid(row=row, column=col, padx=10, pady=5)

        # 악기 선택
        inst_frame = ttk.LabelFrame(main_frame, text="Instruments", padding="10")
        inst_frame.pack(fill=tk.X, pady=10)

        self.synth_var = tk.BooleanVar(value=True)
        self.guitar_var = tk.BooleanVar(value=True)
        self.bass_var = tk.BooleanVar(value=True)
        self.drums_var = tk.BooleanVar(value=True)

        instruments = [
            ("Synthesizer", self.synth_var, "Pad, Square, Sawtooth"),
            ("Electric Guitar", self.guitar_var, "Clean, Distortion"),
            ("Electric Bass", self.bass_var, "Finger, Slap"),
            ("Drum Machine", self.drums_var, "Kick, Snare, HiHat"),
        ]

        for text, var, desc in instruments:
            frame = ttk.Frame(inst_frame)
            frame.pack(fill=tk.X, pady=3)
            cb = ttk.Checkbutton(frame, text=text, variable=var)
            cb.pack(side=tk.LEFT)
            desc_label = ttk.Label(frame, text=f"({desc})",
                                    foreground='gray')
            desc_label.pack(side=tk.LEFT, padx=(10, 0))

        # BPM 설정
        bpm_frame = ttk.LabelFrame(main_frame, text="BPM", padding="10")
        bpm_frame.pack(fill=tk.X, pady=10)

        bpm_inner = ttk.Frame(bpm_frame)
        bpm_inner.pack()

        self.bpm_var = tk.IntVar(value=120)
        self.bpm_label = ttk.Label(bpm_inner, text="120", width=4)
        self.bpm_label.pack(side=tk.LEFT)

        bpm_scale = ttk.Scale(bpm_inner, from_=60, to=180,
                               variable=self.bpm_var, orient=tk.HORIZONTAL,
                               length=300, command=self.update_bpm_label)
        bpm_scale.pack(side=tk.LEFT, padx=10)

        # 마디 수 설정
        bars_frame = ttk.LabelFrame(main_frame, text="Bars", padding="10")
        bars_frame.pack(fill=tk.X, pady=10)

        bars_inner = ttk.Frame(bars_frame)
        bars_inner.pack()

        self.bars_var = tk.IntVar(value=8)
        for bars in [4, 8, 16]:
            rb = ttk.Radiobutton(bars_inner, text=f"{bars} bars",
                                  value=bars, variable=self.bars_var)
            rb.pack(side=tk.LEFT, padx=20)

        # 버튼 프레임
        btn_frame = ttk.Frame(main_frame)
        btn_frame.pack(fill=tk.X, pady=20)

        self.compose_btn = ttk.Button(btn_frame, text="Compose",
                                       command=self.compose_music)
        self.compose_btn.pack(side=tk.LEFT, padx=5, expand=True, fill=tk.X)

        self.play_btn = ttk.Button(btn_frame, text="Play",
                                    command=self.play_music, state=tk.DISABLED)
        self.play_btn.pack(side=tk.LEFT, padx=5, expand=True, fill=tk.X)

        self.stop_btn = ttk.Button(btn_frame, text="Stop",
                                    command=self.stop_music, state=tk.DISABLED)
        self.stop_btn.pack(side=tk.LEFT, padx=5, expand=True, fill=tk.X)

        # 상태 표시
        self.status_var = tk.StringVar(value="Ready")
        status_label = ttk.Label(main_frame, textvariable=self.status_var,
                                  font=('Helvetica', 10))
        status_label.pack(pady=10)

        # 프로그레스 바
        self.progress = ttk.Progressbar(main_frame, mode='indeterminate')
        self.progress.pack(fill=tk.X, pady=5)

    def update_bpm_label(self, value):
        self.bpm_label.config(text=str(int(float(value))))

    def on_style_change(self):
        """스타일 변경 시 BPM 자동 조정"""
        style = self.style_var.get()
        recommended_bpm = STYLE_BPM.get(style, 120)
        self.bpm_var.set(recommended_bpm)
        self.bpm_label.config(text=str(recommended_bpm))

    def compose_music(self):
        """음악 작곡"""
        if self.is_composing:
            return

        # 악기 체크
        instruments = {
            'synth': self.synth_var.get(),
            'guitar': self.guitar_var.get(),
            'bass': self.bass_var.get(),
            'drums': self.drums_var.get(),
        }

        if not any(instruments.values()):
            messagebox.showwarning("Warning", "Please select at least one instrument!")
            return

        self.is_composing = True
        self.compose_btn.config(state=tk.DISABLED)
        self.play_btn.config(state=tk.DISABLED)
        self.status_var.set("Composing...")
        self.progress.start(10)

        # 백그라운드에서 작곡
        def compose_thread():
            try:
                self.composer.set_bpm(self.bpm_var.get())
                style = self.style_var.get()
                bars = self.bars_var.get()

                music = self.composer.compose(style, instruments, bars)
                self.current_file = f"composed_{style}.wav"
                self.composer.save_wav(music, self.current_file)

                self.root.after(0, self.compose_complete)
            except Exception as e:
                self.root.after(0, lambda: self.compose_error(str(e)))

        thread = threading.Thread(target=compose_thread)
        thread.start()

    def compose_complete(self):
        """작곡 완료"""
        self.is_composing = False
        self.progress.stop()
        self.compose_btn.config(state=tk.NORMAL)
        self.play_btn.config(state=tk.NORMAL)
        self.stop_btn.config(state=tk.NORMAL)
        self.status_var.set(f"Saved: {self.current_file}")

    def compose_error(self, error):
        """작곡 에러"""
        self.is_composing = False
        self.progress.stop()
        self.compose_btn.config(state=tk.NORMAL)
        self.status_var.set("Error occurred")
        messagebox.showerror("Error", f"Composition failed: {error}")

    def play_music(self):
        """음악 재생"""
        if self.current_file and os.path.exists(self.current_file):
            self.status_var.set(f"Playing: {self.current_file}")
            # 비동기 재생
            def play_thread():
                try:
                    winsound.PlaySound(self.current_file, winsound.SND_FILENAME)
                    self.root.after(0, lambda: self.status_var.set("Playback finished"))
                except Exception as e:
                    self.root.after(0, lambda: self.status_var.set(f"Error: {e}"))

            thread = threading.Thread(target=play_thread)
            thread.start()

    def stop_music(self):
        """음악 정지"""
        try:
            winsound.PlaySound(None, winsound.SND_PURGE)
            self.status_var.set("Stopped")
        except:
            pass


def main():
    root = tk.Tk()
    app = MusicComposerApp(root)
    root.mainloop()


if __name__ == "__main__":
    main()
