"""
전기 악기 음악 작곡 앱 (악보 편집 기능 포함)
Electric Instrument Music Composer with Score Editor

GUI를 통해 스타일과 악기를 선택하고, 악보를 편집하여 음악을 작곡합니다.
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
NOTE_NAMES = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']
NOTE_FREQUENCIES = {}
for octave in range(2, 7):
    for i, note in enumerate(NOTE_NAMES):
        note_name = f"{note}{octave}"
        # A4 = 440Hz 기준 계산
        semitones_from_a4 = (octave - 4) * 12 + (i - 9)
        NOTE_FREQUENCIES[note_name] = 440.0 * (2 ** (semitones_from_a4 / 12))

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
    'ballad': ['G4', 'D4', 'E4', 'C4'],
    'trot': ['A4', 'D4', 'E4', 'A4'],
}

# 스타일별 기본 BPM
STYLE_BPM = {
    'electronic': 128,
    'rock': 120,
    'pop': 110,
    'jazz': 95,
    'ambient': 70,
    'ballad': 72,
    'trot': 115,
}


class Note:
    """음표 클래스"""
    def __init__(self, pitch, start_beat, duration=1, velocity=0.8):
        self.pitch = pitch  # 예: 'C4', 'E4'
        self.start_beat = start_beat  # 시작 비트 (0부터)
        self.duration = duration  # 비트 단위 길이
        self.velocity = velocity  # 음량 (0.0 ~ 1.0)

    def get_frequency(self):
        return NOTE_FREQUENCIES.get(self.pitch, 440.0)

    def __repr__(self):
        return f"Note({self.pitch}, beat={self.start_beat}, dur={self.duration})"


class Track:
    """트랙 클래스 - 한 악기의 노트들을 관리"""
    def __init__(self, name, instrument_type):
        self.name = name
        self.instrument_type = instrument_type  # 'synth', 'guitar', 'bass', 'drums'
        self.notes = []
        self.muted = False
        self.volume = 0.8

    def add_note(self, note):
        self.notes.append(note)

    def remove_note(self, note):
        if note in self.notes:
            self.notes.remove(note)

    def get_note_at(self, pitch, beat):
        for note in self.notes:
            if note.pitch == pitch and note.start_beat <= beat < note.start_beat + note.duration:
                return note
        return None

    def clear(self):
        self.notes = []


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


class ScoreEditor(tk.Toplevel):
    """악보 편집기 윈도우"""

    # 표시할 음 목록 (아래에서 위로)
    VISIBLE_NOTES = ['C3', 'D3', 'E3', 'F3', 'G3', 'A3', 'B3',
                     'C4', 'D4', 'E4', 'F4', 'G4', 'A4', 'B4',
                     'C5', 'D5', 'E5', 'F5', 'G5', 'A5', 'B5']

    # 드럼 노트 (특별 처리)
    DRUM_NOTES = ['Kick', 'Snare', 'HiHat']

    def __init__(self, parent, track, total_beats=32, bpm=120):
        super().__init__(parent)
        self.track = track
        self.total_beats = total_beats
        self.bpm = bpm
        self.parent_app = parent

        self.title(f"Score Editor - {track.name}")
        self.geometry("1000x600")

        # 그리드 설정
        self.cell_width = 25
        self.cell_height = 20
        self.note_labels_width = 50

        self.selected_note = None
        self.is_dragging = False

        self.setup_ui()
        self.draw_grid()
        self.draw_notes()

    def setup_ui(self):
        """UI 설정"""
        # 상단 툴바
        toolbar = ttk.Frame(self)
        toolbar.pack(fill=tk.X, padx=5, pady=5)

        ttk.Button(toolbar, text="Clear All", command=self.clear_all).pack(side=tk.LEFT, padx=2)
        ttk.Button(toolbar, text="Auto Generate", command=self.auto_generate).pack(side=tk.LEFT, padx=2)

        ttk.Separator(toolbar, orient=tk.VERTICAL).pack(side=tk.LEFT, padx=10, fill=tk.Y)

        ttk.Label(toolbar, text="Velocity:").pack(side=tk.LEFT, padx=2)
        self.velocity_var = tk.DoubleVar(value=0.8)
        velocity_scale = ttk.Scale(toolbar, from_=0.1, to=1.0, variable=self.velocity_var,
                                    orient=tk.HORIZONTAL, length=100)
        velocity_scale.pack(side=tk.LEFT, padx=2)

        ttk.Button(toolbar, text="Apply & Close", command=self.apply_and_close).pack(side=tk.RIGHT, padx=2)

        # 메인 프레임 (스크롤 가능)
        main_frame = ttk.Frame(self)
        main_frame.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)

        # 캔버스와 스크롤바
        self.canvas = tk.Canvas(main_frame, bg='#2a2a2a', highlightthickness=0)

        h_scroll = ttk.Scrollbar(main_frame, orient=tk.HORIZONTAL, command=self.canvas.xview)
        v_scroll = ttk.Scrollbar(main_frame, orient=tk.VERTICAL, command=self.canvas.yview)

        self.canvas.configure(xscrollcommand=h_scroll.set, yscrollcommand=v_scroll.set)

        h_scroll.pack(side=tk.BOTTOM, fill=tk.X)
        v_scroll.pack(side=tk.RIGHT, fill=tk.Y)
        self.canvas.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)

        # 캔버스 이벤트
        self.canvas.bind('<Button-1>', self.on_click)
        self.canvas.bind('<B1-Motion>', self.on_drag)
        self.canvas.bind('<ButtonRelease-1>', self.on_release)
        self.canvas.bind('<Button-3>', self.on_right_click)

        # 범례
        legend = ttk.Frame(self)
        legend.pack(fill=tk.X, padx=5, pady=5)
        ttk.Label(legend, text="Left Click: Add/Select Note | Right Click: Delete Note | Drag: Move Note").pack()

    def get_notes_list(self):
        """현재 트랙에 맞는 노트 목록 반환"""
        if self.track.instrument_type == 'drums':
            return self.DRUM_NOTES
        return self.VISIBLE_NOTES

    def draw_grid(self):
        """그리드 그리기"""
        notes = self.get_notes_list()
        num_notes = len(notes)

        canvas_width = self.note_labels_width + self.total_beats * self.cell_width + 20
        canvas_height = num_notes * self.cell_height + 20

        self.canvas.configure(scrollregion=(0, 0, canvas_width, canvas_height))

        # 배경
        self.canvas.create_rectangle(0, 0, canvas_width, canvas_height, fill='#2a2a2a', outline='')

        # 음 이름 레이블
        for i, note in enumerate(reversed(notes)):
            y = i * self.cell_height
            # 음 이름
            self.canvas.create_text(self.note_labels_width - 5, y + self.cell_height // 2,
                                     text=note, anchor='e', fill='white', font=('Consolas', 9))
            # 행 배경 (흰 건반/검은 건반 구분)
            if self.track.instrument_type != 'drums' and '#' in note:
                color = '#1a1a1a'
            else:
                color = '#2a2a2a'
            self.canvas.create_rectangle(self.note_labels_width, y,
                                          canvas_width, y + self.cell_height,
                                          fill=color, outline='#444')

        # 비트 라인
        for beat in range(self.total_beats + 1):
            x = self.note_labels_width + beat * self.cell_width
            # 마디선 (4비트마다)
            if beat % 4 == 0:
                color = '#888'
                width = 2
                # 마디 번호
                bar_num = beat // 4 + 1
                self.canvas.create_text(x + 2, 5, text=str(bar_num), anchor='nw',
                                         fill='#aaa', font=('Consolas', 8))
            else:
                color = '#444'
                width = 1
            self.canvas.create_line(x, 0, x, canvas_height, fill=color, width=width)

    def draw_notes(self):
        """노트 그리기"""
        self.canvas.delete('note')
        notes_list = self.get_notes_list()

        for note in self.track.notes:
            self.draw_single_note(note, notes_list)

    def draw_single_note(self, note, notes_list=None):
        """단일 노트 그리기"""
        if notes_list is None:
            notes_list = self.get_notes_list()

        if note.pitch not in notes_list:
            return

        note_idx = len(notes_list) - 1 - notes_list.index(note.pitch)
        x = self.note_labels_width + note.start_beat * self.cell_width
        y = note_idx * self.cell_height

        # 노트 색상 (velocity에 따라)
        intensity = int(100 + note.velocity * 155)
        if self.track.instrument_type == 'synth':
            color = f'#{intensity:02x}60{intensity:02x}'  # 보라색
        elif self.track.instrument_type == 'guitar':
            color = f'#{intensity:02x}{intensity:02x}60'  # 노란색
        elif self.track.instrument_type == 'bass':
            color = f'#60{intensity:02x}60'  # 초록색
        else:  # drums
            color = f'#{intensity:02x}6060'  # 빨간색

        # 노트 사각형
        rect = self.canvas.create_rectangle(
            x + 2, y + 2,
            x + note.duration * self.cell_width - 2, y + self.cell_height - 2,
            fill=color, outline='white', width=1, tags='note'
        )

        # 노트에 데이터 연결
        self.canvas.itemconfig(rect, tags=('note', f'note_{id(note)}'))

    def on_click(self, event):
        """클릭 이벤트"""
        x = self.canvas.canvasx(event.x)
        y = self.canvas.canvasy(event.y)

        if x < self.note_labels_width:
            return

        notes_list = self.get_notes_list()
        beat = int((x - self.note_labels_width) / self.cell_width)
        note_idx = int(y / self.cell_height)

        if beat < 0 or beat >= self.total_beats:
            return
        if note_idx < 0 or note_idx >= len(notes_list):
            return

        pitch = notes_list[len(notes_list) - 1 - note_idx]

        # 기존 노트가 있는지 확인
        existing_note = self.track.get_note_at(pitch, beat)

        if existing_note:
            # 기존 노트 선택
            self.selected_note = existing_note
            self.is_dragging = True
            self.drag_start_beat = beat
        else:
            # 새 노트 추가
            new_note = Note(pitch, beat, duration=1, velocity=self.velocity_var.get())
            self.track.add_note(new_note)
            self.draw_notes()

    def on_drag(self, event):
        """드래그 이벤트"""
        if not self.is_dragging or not self.selected_note:
            return

        x = self.canvas.canvasx(event.x)
        beat = int((x - self.note_labels_width) / self.cell_width)
        beat = max(0, min(beat, self.total_beats - 1))

        if beat != self.selected_note.start_beat:
            self.selected_note.start_beat = beat
            self.draw_notes()

    def on_release(self, event):
        """마우스 릴리즈"""
        self.is_dragging = False
        self.selected_note = None

    def on_right_click(self, event):
        """우클릭 - 노트 삭제"""
        x = self.canvas.canvasx(event.x)
        y = self.canvas.canvasy(event.y)

        if x < self.note_labels_width:
            return

        notes_list = self.get_notes_list()
        beat = int((x - self.note_labels_width) / self.cell_width)
        note_idx = int(y / self.cell_height)

        if note_idx < 0 or note_idx >= len(notes_list):
            return

        pitch = notes_list[len(notes_list) - 1 - note_idx]

        # 해당 위치의 노트 찾아서 삭제
        note_to_remove = self.track.get_note_at(pitch, beat)
        if note_to_remove:
            self.track.remove_note(note_to_remove)
            self.draw_notes()

    def clear_all(self):
        """모든 노트 삭제"""
        if messagebox.askyesno("Clear All", "Delete all notes?"):
            self.track.clear()
            self.draw_notes()

    def auto_generate(self):
        """자동 생성"""
        self.track.clear()

        notes_list = self.get_notes_list()

        if self.track.instrument_type == 'drums':
            # 드럼 패턴 자동 생성
            for beat in range(self.total_beats):
                if beat % 4 == 0:  # 킥
                    self.track.add_note(Note('Kick', beat, 1, 0.9))
                if beat % 4 == 2:  # 스네어
                    self.track.add_note(Note('Snare', beat, 1, 0.8))
                if beat % 2 == 0:  # 하이햇
                    self.track.add_note(Note('HiHat', beat, 1, 0.6))
        else:
            # 멜로디/코드 자동 생성
            scale = ['C4', 'D4', 'E4', 'F4', 'G4', 'A4', 'B4']
            for beat in range(0, self.total_beats, 2):
                if random.random() > 0.3:
                    pitch = random.choice(scale)
                    duration = random.choice([1, 2])
                    self.track.add_note(Note(pitch, beat, duration, random.uniform(0.6, 1.0)))

        self.draw_notes()

    def apply_and_close(self):
        """적용하고 닫기"""
        self.destroy()


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

    def render_track(self, track, total_beats):
        """트랙을 오디오로 렌더링"""
        total_duration = total_beats * self.beat_duration
        total_samples = int(SAMPLE_RATE * total_duration)
        audio = np.zeros(total_samples)

        for note in track.notes:
            start_sample = int(note.start_beat * self.beat_duration * SAMPLE_RATE)
            duration = note.duration * self.beat_duration

            if track.instrument_type == 'synth':
                wave = self.synth.pad_sound(note.get_frequency(), duration, note.velocity)
            elif track.instrument_type == 'guitar':
                wave = self.guitar.clean_tone(note.get_frequency(), duration, note.velocity)
            elif track.instrument_type == 'bass':
                freq = note.get_frequency() / 2  # 옥타브 낮춤
                wave = self.bass.finger_bass(freq, duration, note.velocity)
            elif track.instrument_type == 'drums':
                if note.pitch == 'Kick':
                    wave = self.drums.kick(velocity=note.velocity)
                elif note.pitch == 'Snare':
                    wave = self.drums.snare(velocity=note.velocity)
                elif note.pitch == 'HiHat':
                    wave = self.drums.hihat(velocity=note.velocity)
                else:
                    continue
            else:
                continue

            end_sample = min(start_sample + len(wave), total_samples)
            audio[start_sample:end_sample] += wave[:end_sample - start_sample]

        return audio * track.volume

    def compose_from_tracks(self, tracks, total_beats):
        """트랙들을 합쳐서 최종 오디오 생성"""
        total_duration = total_beats * self.beat_duration
        total_samples = int(SAMPLE_RATE * total_duration)
        mix = np.zeros(total_samples)

        for track in tracks:
            if not track.muted and track.notes:
                track_audio = self.render_track(track, total_beats)
                if len(track_audio) < total_samples:
                    track_audio = np.pad(track_audio, (0, total_samples - len(track_audio)))
                mix += track_audio[:total_samples]

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
        self.root.title("Electric Music Composer with Score Editor")
        self.root.geometry("600x750")
        self.root.resizable(False, False)

        self.composer = MusicComposer()
        self.current_file = None
        self.is_composing = False

        # 트랙 초기화
        self.tracks = {
            'synth': Track("Synthesizer", "synth"),
            'guitar': Track("Electric Guitar", "guitar"),
            'bass': Track("Electric Bass", "bass"),
            'drums': Track("Drum Machine", "drums"),
        }

        self.total_beats = 32  # 8마디 (4비트 x 8)

        self.setup_ui()

    def setup_ui(self):
        """UI 설정"""
        main_frame = ttk.Frame(self.root, padding="20")
        main_frame.pack(fill=tk.BOTH, expand=True)

        # 제목
        title_label = ttk.Label(main_frame, text="Electric Music Composer",
                                 font=('Helvetica', 18, 'bold'))
        title_label.pack(pady=(0, 10))

        subtitle = ttk.Label(main_frame, text="with Score Editor",
                              font=('Helvetica', 12))
        subtitle.pack(pady=(0, 15))

        # 스타일 선택
        style_frame = ttk.LabelFrame(main_frame, text="Style (Auto-generate)", padding="10")
        style_frame.pack(fill=tk.X, pady=5)

        self.style_var = tk.StringVar(value="electronic")
        styles = [
            ("Electronic", "electronic"), ("Rock", "rock"), ("Pop", "pop"),
            ("Jazz", "jazz"), ("Ambient", "ambient"), ("Ballad", "ballad"), ("Trot", "trot"),
        ]

        style_inner = ttk.Frame(style_frame)
        style_inner.pack()

        for i, (text, value) in enumerate(styles):
            rb = ttk.Radiobutton(style_inner, text=text, value=value,
                                  variable=self.style_var, command=self.on_style_change)
            row = 0 if i < 4 else 1
            col = i if i < 4 else i - 4
            rb.grid(row=row, column=col, padx=8, pady=3)

        # 악기/트랙 선택 및 악보 편집
        tracks_frame = ttk.LabelFrame(main_frame, text="Tracks & Score Editor", padding="10")
        tracks_frame.pack(fill=tk.X, pady=10)

        self.track_vars = {}
        track_info = [
            ("synth", "Synthesizer", "Pad sounds"),
            ("guitar", "Electric Guitar", "Clean/Distortion"),
            ("bass", "Electric Bass", "Finger bass"),
            ("drums", "Drum Machine", "Kick/Snare/HiHat"),
        ]

        for track_id, name, desc in track_info:
            frame = ttk.Frame(tracks_frame)
            frame.pack(fill=tk.X, pady=3)

            self.track_vars[track_id] = tk.BooleanVar(value=True)
            cb = ttk.Checkbutton(frame, text=name, variable=self.track_vars[track_id])
            cb.pack(side=tk.LEFT)

            ttk.Label(frame, text=f"({desc})", foreground='gray').pack(side=tk.LEFT, padx=(5, 0))

            # 악보 편집 버튼
            edit_btn = ttk.Button(frame, text="Edit Score",
                                   command=lambda t=track_id: self.open_score_editor(t))
            edit_btn.pack(side=tk.RIGHT, padx=2)

            # 노트 수 표시
            note_label = ttk.Label(frame, text="0 notes", foreground='blue')
            note_label.pack(side=tk.RIGHT, padx=5)
            setattr(self, f'{track_id}_note_label', note_label)

        # BPM 설정
        bpm_frame = ttk.LabelFrame(main_frame, text="BPM", padding="10")
        bpm_frame.pack(fill=tk.X, pady=5)

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
        bars_frame.pack(fill=tk.X, pady=5)

        bars_inner = ttk.Frame(bars_frame)
        bars_inner.pack()

        self.bars_var = tk.IntVar(value=8)
        for bars in [4, 8, 16]:
            rb = ttk.Radiobutton(bars_inner, text=f"{bars} bars",
                                  value=bars, variable=self.bars_var,
                                  command=self.on_bars_change)
            rb.pack(side=tk.LEFT, padx=15)

        # 버튼 프레임
        btn_frame = ttk.Frame(main_frame)
        btn_frame.pack(fill=tk.X, pady=15)

        ttk.Button(btn_frame, text="Auto Generate All",
                   command=self.auto_generate_all).pack(side=tk.LEFT, padx=3, expand=True, fill=tk.X)

        self.compose_btn = ttk.Button(btn_frame, text="Compose",
                                       command=self.compose_music)
        self.compose_btn.pack(side=tk.LEFT, padx=3, expand=True, fill=tk.X)

        self.play_btn = ttk.Button(btn_frame, text="Play",
                                    command=self.play_music, state=tk.DISABLED)
        self.play_btn.pack(side=tk.LEFT, padx=3, expand=True, fill=tk.X)

        self.stop_btn = ttk.Button(btn_frame, text="Stop",
                                    command=self.stop_music, state=tk.DISABLED)
        self.stop_btn.pack(side=tk.LEFT, padx=3, expand=True, fill=tk.X)

        # 상태 표시
        self.status_var = tk.StringVar(value="Ready - Edit scores or auto-generate")
        status_label = ttk.Label(main_frame, textvariable=self.status_var,
                                  font=('Helvetica', 10))
        status_label.pack(pady=10)

        # 프로그레스 바
        self.progress = ttk.Progressbar(main_frame, mode='indeterminate')
        self.progress.pack(fill=tk.X, pady=5)

    def update_note_counts(self):
        """노트 수 업데이트"""
        for track_id, track in self.tracks.items():
            label = getattr(self, f'{track_id}_note_label')
            count = len(track.notes)
            label.config(text=f"{count} notes")

    def open_score_editor(self, track_id):
        """악보 편집기 열기"""
        track = self.tracks[track_id]
        self.total_beats = self.bars_var.get() * 4
        editor = ScoreEditor(self.root, track, self.total_beats, self.bpm_var.get())
        editor.grab_set()
        self.root.wait_window(editor)
        self.update_note_counts()

    def on_style_change(self):
        """스타일 변경"""
        style = self.style_var.get()
        recommended_bpm = STYLE_BPM.get(style, 120)
        self.bpm_var.set(recommended_bpm)
        self.bpm_label.config(text=str(recommended_bpm))

    def on_bars_change(self):
        """마디 수 변경"""
        self.total_beats = self.bars_var.get() * 4

    def update_bpm_label(self, value):
        self.bpm_label.config(text=str(int(float(value))))

    def auto_generate_all(self):
        """모든 트랙 자동 생성"""
        style = self.style_var.get()
        self.total_beats = self.bars_var.get() * 4
        progression = PROGRESSIONS.get(style, PROGRESSIONS['electronic'])

        # 각 트랙 클리어 후 자동 생성
        for track_id, track in self.tracks.items():
            track.clear()

            if track_id == 'drums':
                # 드럼 패턴
                for beat in range(self.total_beats):
                    if style == 'ballad':
                        if beat % 4 == 0:
                            track.add_note(Note('Kick', beat, 1, 0.6))
                        if beat % 4 == 2:
                            track.add_note(Note('Snare', beat, 1, 0.5))
                        if beat % 2 == 0:
                            track.add_note(Note('HiHat', beat, 1, 0.3))
                    elif style == 'trot':
                        if beat % 2 == 0:
                            track.add_note(Note('Kick', beat, 1, 0.9))
                        if beat % 2 == 1:
                            track.add_note(Note('Snare', beat, 1, 0.8))
                            track.add_note(Note('HiHat', beat, 1, 0.6))
                    else:
                        if beat % 4 == 0 or beat % 4 == 2:
                            track.add_note(Note('Kick', beat, 1, 0.8))
                        if beat % 4 == 1 or beat % 4 == 3:
                            track.add_note(Note('Snare', beat, 1, 0.7))
                        if beat % 2 == 0:
                            track.add_note(Note('HiHat', beat, 1, 0.5))

            elif track_id == 'bass':
                # 베이스라인
                for bar in range(self.total_beats // 4):
                    root = progression[bar % len(progression)]
                    root_note = root.replace('4', '3').replace('5', '4')
                    for i in range(4):
                        beat = bar * 4 + i
                        if i == 0:
                            track.add_note(Note(root_note, beat, 1, 0.9))
                        elif i == 2:
                            track.add_note(Note(root_note, beat, 1, 0.7))

            elif track_id == 'synth':
                # 신디사이저 코드
                for bar in range(self.total_beats // 4):
                    root = progression[bar % len(progression)]
                    beat = bar * 4
                    track.add_note(Note(root, beat, 4, 0.6))
                    # 3도 추가
                    third = self.get_third(root)
                    if third:
                        track.add_note(Note(third, beat, 4, 0.5))
                    # 5도 추가
                    fifth = self.get_fifth(root)
                    if fifth:
                        track.add_note(Note(fifth, beat, 4, 0.5))

            elif track_id == 'guitar':
                # 기타 아르페지오
                for bar in range(self.total_beats // 4):
                    root = progression[bar % len(progression)]
                    for i in range(4):
                        beat = bar * 4 + i
                        if i % 2 == 0:
                            track.add_note(Note(root, beat, 1, 0.7))

        self.update_note_counts()
        self.status_var.set(f"Auto-generated {style} pattern")

    def get_third(self, root):
        """3도 음 구하기"""
        note_map = {'C': 'E', 'D': 'F', 'E': 'G', 'F': 'A', 'G': 'B', 'A': 'C', 'B': 'D'}
        base = root[:-1]
        octave = root[-1]
        if base in note_map:
            new_base = note_map[base]
            new_octave = str(int(octave) + 1) if base in ['A', 'B'] else octave
            return new_base + new_octave
        return None

    def get_fifth(self, root):
        """5도 음 구하기"""
        note_map = {'C': 'G', 'D': 'A', 'E': 'B', 'F': 'C', 'G': 'D', 'A': 'E', 'B': 'F'}
        base = root[:-1]
        octave = root[-1]
        if base in note_map:
            new_base = note_map[base]
            new_octave = str(int(octave) + 1) if base in ['F', 'G', 'A', 'B'] else octave
            return new_base + new_octave
        return None

    def compose_music(self):
        """음악 작곡 (트랙 기반)"""
        if self.is_composing:
            return

        # 활성 트랙 확인
        active_tracks = [self.tracks[t] for t in self.tracks
                         if self.track_vars[t].get() and self.tracks[t].notes]

        if not active_tracks:
            messagebox.showwarning("Warning", "No tracks with notes! Add notes or auto-generate first.")
            return

        self.is_composing = True
        self.compose_btn.config(state=tk.DISABLED)
        self.play_btn.config(state=tk.DISABLED)
        self.status_var.set("Composing from score...")
        self.progress.start(10)

        def compose_thread():
            try:
                self.composer.set_bpm(self.bpm_var.get())
                self.total_beats = self.bars_var.get() * 4

                music = self.composer.compose_from_tracks(active_tracks, self.total_beats)

                style = self.style_var.get()
                self.current_file = f"composed_{style}_custom.wav"
                self.composer.save_wav(music, self.current_file)

                self.root.after(0, self.compose_complete)
            except Exception as e:
                self.root.after(0, lambda: self.compose_error(str(e)))

        thread = threading.Thread(target=compose_thread)
        thread.start()

    def compose_complete(self):
        self.is_composing = False
        self.progress.stop()
        self.compose_btn.config(state=tk.NORMAL)
        self.play_btn.config(state=tk.NORMAL)
        self.stop_btn.config(state=tk.NORMAL)
        self.status_var.set(f"Saved: {self.current_file}")

    def compose_error(self, error):
        self.is_composing = False
        self.progress.stop()
        self.compose_btn.config(state=tk.NORMAL)
        self.status_var.set("Error occurred")
        messagebox.showerror("Error", f"Composition failed: {error}")

    def play_music(self):
        if self.current_file and os.path.exists(self.current_file):
            self.status_var.set(f"Playing: {self.current_file}")

            def play_thread():
                try:
                    winsound.PlaySound(self.current_file, winsound.SND_FILENAME)
                    self.root.after(0, lambda: self.status_var.set("Playback finished"))
                except Exception as e:
                    self.root.after(0, lambda: self.status_var.set(f"Error: {e}"))

            thread = threading.Thread(target=play_thread)
            thread.start()

    def stop_music(self):
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
