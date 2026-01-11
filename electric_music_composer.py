"""
전기 악기 음악 작곡 프로그램
Electric Instrument Music Composer

다양한 전기 악기(신디사이저, 일렉트릭 기타, 베이스, 드럼머신)를
조합하여 음악을 자동으로 작곡합니다.
"""

import numpy as np
from scipy.io import wavfile
import random
from dataclasses import dataclass
from typing import List, Tuple

# 샘플링 레이트
SAMPLE_RATE = 44100

# 음계 주파수 (Hz) - C4부터 시작
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

# 코드 정의 (근음 기준 반음 간격)
CHORD_PATTERNS = {
    'major': [0, 4, 7],
    'minor': [0, 3, 7],
    'seventh': [0, 4, 7, 10],
    'minor7': [0, 3, 7, 10],
    'sus4': [0, 5, 7],
    'power': [0, 7, 12],
}

# 코드 진행 패턴
PROGRESSIONS = [
    ['C4', 'G4', 'A4', 'F4'],      # I-V-vi-IV (팝)
    ['A4', 'D4', 'E4', 'A4'],      # i-iv-V-i (마이너)
    ['C4', 'F4', 'G4', 'C4'],      # I-IV-V-I (클래식)
    ['E4', 'A4', 'B4', 'E4'],      # 록 진행
]


@dataclass
class Note:
    """음표 데이터 클래스"""
    frequency: float
    duration: float
    velocity: float = 1.0


class Synthesizer:
    """신디사이저 - 다양한 파형 생성"""

    @staticmethod
    def sine_wave(freq: float, duration: float, velocity: float = 1.0) -> np.ndarray:
        """사인파 (부드러운 소리)"""
        t = np.linspace(0, duration, int(SAMPLE_RATE * duration), False)
        wave = np.sin(2 * np.pi * freq * t) * velocity
        return Synthesizer._apply_envelope(wave, duration)

    @staticmethod
    def square_wave(freq: float, duration: float, velocity: float = 1.0) -> np.ndarray:
        """사각파 (8비트 느낌)"""
        t = np.linspace(0, duration, int(SAMPLE_RATE * duration), False)
        wave = np.sign(np.sin(2 * np.pi * freq * t)) * velocity * 0.5
        return Synthesizer._apply_envelope(wave, duration)

    @staticmethod
    def sawtooth_wave(freq: float, duration: float, velocity: float = 1.0) -> np.ndarray:
        """톱니파 (밝은 소리)"""
        t = np.linspace(0, duration, int(SAMPLE_RATE * duration), False)
        wave = 2 * (t * freq - np.floor(0.5 + t * freq)) * velocity * 0.5
        return Synthesizer._apply_envelope(wave, duration)

    @staticmethod
    def pad_sound(freq: float, duration: float, velocity: float = 1.0) -> np.ndarray:
        """패드 사운드 (풍부한 앰비언트)"""
        t = np.linspace(0, duration, int(SAMPLE_RATE * duration), False)
        # 여러 옥타브 레이어링
        wave = (np.sin(2 * np.pi * freq * t) * 0.5 +
                np.sin(2 * np.pi * freq * 2 * t) * 0.25 +
                np.sin(2 * np.pi * freq * 0.5 * t) * 0.25)
        wave *= velocity
        # 느린 어택, 긴 릴리즈
        return Synthesizer._apply_envelope(wave, duration, attack=0.3, release=0.4)

    @staticmethod
    def _apply_envelope(wave: np.ndarray, duration: float,
                        attack: float = 0.05, release: float = 0.1) -> np.ndarray:
        """ADSR 엔벨로프 적용"""
        samples = len(wave)
        attack_samples = int(attack * SAMPLE_RATE)
        release_samples = int(release * SAMPLE_RATE)

        envelope = np.ones(samples)
        # Attack
        if attack_samples > 0:
            envelope[:attack_samples] = np.linspace(0, 1, attack_samples)
        # Release
        if release_samples > 0:
            envelope[-release_samples:] = np.linspace(1, 0, release_samples)

        return wave * envelope


class ElectricGuitar:
    """일렉트릭 기타 사운드"""

    @staticmethod
    def clean_tone(freq: float, duration: float, velocity: float = 1.0) -> np.ndarray:
        """클린 톤"""
        t = np.linspace(0, duration, int(SAMPLE_RATE * duration), False)
        # 하모닉스 추가
        wave = (np.sin(2 * np.pi * freq * t) * 0.6 +
                np.sin(2 * np.pi * freq * 2 * t) * 0.25 +
                np.sin(2 * np.pi * freq * 3 * t) * 0.1 +
                np.sin(2 * np.pi * freq * 4 * t) * 0.05)
        wave *= velocity
        return Synthesizer._apply_envelope(wave, duration, attack=0.01, release=0.2)

    @staticmethod
    def distortion(freq: float, duration: float, velocity: float = 1.0) -> np.ndarray:
        """디스토션 (오버드라이브)"""
        t = np.linspace(0, duration, int(SAMPLE_RATE * duration), False)
        wave = np.sin(2 * np.pi * freq * t)
        # 클리핑으로 디스토션 효과
        wave = np.clip(wave * 3, -0.8, 0.8)
        # 추가 하모닉스
        wave += np.sin(2 * np.pi * freq * 2 * t) * 0.3
        wave = np.clip(wave, -1, 1) * velocity * 0.7
        return Synthesizer._apply_envelope(wave, duration, attack=0.01, release=0.15)

    @staticmethod
    def power_chord(root_freq: float, duration: float, velocity: float = 1.0) -> np.ndarray:
        """파워 코드"""
        fifth_freq = root_freq * 1.5  # 완전 5도
        octave_freq = root_freq * 2

        wave = (ElectricGuitar.distortion(root_freq, duration, velocity) * 0.4 +
                ElectricGuitar.distortion(fifth_freq, duration, velocity) * 0.35 +
                ElectricGuitar.distortion(octave_freq, duration, velocity) * 0.25)
        return wave


class ElectricBass:
    """일렉트릭 베이스"""

    @staticmethod
    def finger_bass(freq: float, duration: float, velocity: float = 1.0) -> np.ndarray:
        """핑거 베이스"""
        t = np.linspace(0, duration, int(SAMPLE_RATE * duration), False)
        wave = (np.sin(2 * np.pi * freq * t) * 0.7 +
                np.sin(2 * np.pi * freq * 2 * t) * 0.2 +
                np.sin(2 * np.pi * freq * 3 * t) * 0.1)
        wave *= velocity
        return Synthesizer._apply_envelope(wave, duration, attack=0.02, release=0.15)

    @staticmethod
    def slap_bass(freq: float, duration: float, velocity: float = 1.0) -> np.ndarray:
        """슬랩 베이스"""
        t = np.linspace(0, duration, int(SAMPLE_RATE * duration), False)
        wave = (np.sin(2 * np.pi * freq * t) * 0.5 +
                np.sin(2 * np.pi * freq * 2 * t) * 0.3 +
                np.sin(2 * np.pi * freq * 4 * t) * 0.2)
        # 초반에 강한 어택
        attack_samples = int(0.02 * SAMPLE_RATE)
        wave[:attack_samples] *= np.linspace(2, 1, attack_samples)
        wave = np.clip(wave, -1, 1) * velocity
        return Synthesizer._apply_envelope(wave, duration, attack=0.005, release=0.1)


class DrumMachine:
    """드럼 머신"""

    @staticmethod
    def kick(duration: float = 0.3, velocity: float = 1.0) -> np.ndarray:
        """킥 드럼"""
        t = np.linspace(0, duration, int(SAMPLE_RATE * duration), False)
        # 주파수가 빠르게 하강하는 사인파
        freq_envelope = 150 * np.exp(-t * 20) + 40
        phase = np.cumsum(2 * np.pi * freq_envelope / SAMPLE_RATE)
        wave = np.sin(phase) * np.exp(-t * 10) * velocity
        return wave

    @staticmethod
    def snare(duration: float = 0.2, velocity: float = 1.0) -> np.ndarray:
        """스네어 드럼"""
        t = np.linspace(0, duration, int(SAMPLE_RATE * duration), False)
        # 톤 + 노이즈
        tone = np.sin(2 * np.pi * 200 * t) * np.exp(-t * 20)
        noise = np.random.uniform(-1, 1, len(t)) * np.exp(-t * 15) * 0.5
        wave = (tone + noise) * velocity * 0.8
        return wave

    @staticmethod
    def hihat(duration: float = 0.1, velocity: float = 1.0) -> np.ndarray:
        """하이햇"""
        t = np.linspace(0, duration, int(SAMPLE_RATE * duration), False)
        noise = np.random.uniform(-1, 1, len(t))
        # 하이패스 느낌을 위한 고주파 강조
        wave = noise * np.exp(-t * 30) * velocity * 0.4
        return wave

    @staticmethod
    def clap(duration: float = 0.15, velocity: float = 1.0) -> np.ndarray:
        """핸드클랩"""
        t = np.linspace(0, duration, int(SAMPLE_RATE * duration), False)
        noise = np.random.uniform(-1, 1, len(t))
        # 여러 번의 빠른 어택
        envelope = np.zeros(len(t))
        for i in range(4):
            start = int(i * 0.01 * SAMPLE_RATE)
            if start < len(envelope):
                envelope[start:] += np.exp(-np.arange(len(envelope) - start) / SAMPLE_RATE * 50)
        wave = noise * envelope * np.exp(-t * 20) * velocity * 0.5
        return wave


class MusicComposer:
    """음악 작곡기"""

    def __init__(self, bpm: int = 120):
        self.bpm = bpm
        self.beat_duration = 60.0 / bpm  # 한 비트의 길이 (초)
        self.synth = Synthesizer()
        self.guitar = ElectricGuitar()
        self.bass = ElectricBass()
        self.drums = DrumMachine()

    def get_frequency(self, note: str) -> float:
        """음표 이름을 주파수로 변환"""
        return NOTE_FREQUENCIES.get(note, 440.0)

    def generate_chord(self, root_note: str, chord_type: str = 'major',
                       duration: float = 1.0, instrument: str = 'synth') -> np.ndarray:
        """코드 생성"""
        root_freq = self.get_frequency(root_note)
        pattern = CHORD_PATTERNS.get(chord_type, CHORD_PATTERNS['major'])

        chord_wave = np.zeros(int(SAMPLE_RATE * duration))

        for semitones in pattern:
            freq = root_freq * (2 ** (semitones / 12))
            if instrument == 'synth':
                note_wave = self.synth.pad_sound(freq, duration, 0.5)
            elif instrument == 'guitar':
                note_wave = self.guitar.clean_tone(freq, duration, 0.5)
            else:
                note_wave = self.synth.sine_wave(freq, duration, 0.5)

            # 길이 맞추기
            if len(note_wave) < len(chord_wave):
                note_wave = np.pad(note_wave, (0, len(chord_wave) - len(note_wave)))
            chord_wave += note_wave[:len(chord_wave)]

        return chord_wave / len(pattern)

    def generate_melody(self, scale: List[str], bars: int = 4,
                        instrument: str = 'synth') -> np.ndarray:
        """멜로디 생성"""
        melody = []
        notes_per_bar = 8  # 한 마디당 8분음표
        note_duration = self.beat_duration / 2

        for _ in range(bars * notes_per_bar):
            if random.random() < 0.8:  # 80% 확률로 음표
                note = random.choice(scale)
                freq = self.get_frequency(note)
                velocity = random.uniform(0.6, 1.0)

                if instrument == 'synth':
                    wave = self.synth.sawtooth_wave(freq, note_duration, velocity)
                elif instrument == 'square':
                    wave = self.synth.square_wave(freq, note_duration, velocity)
                else:
                    wave = self.synth.sine_wave(freq, note_duration, velocity)

                melody.append(wave)
            else:  # 쉼표
                melody.append(np.zeros(int(SAMPLE_RATE * note_duration)))

        return np.concatenate(melody)

    def generate_bassline(self, root_notes: List[str], bars: int = 4) -> np.ndarray:
        """베이스라인 생성"""
        bassline = []
        beat_duration = self.beat_duration

        for bar in range(bars):
            root = root_notes[bar % len(root_notes)]
            # 옥타브 낮춤
            root_lower = root.replace('4', '3').replace('5', '4')
            freq = self.get_frequency(root_lower)

            # 베이스 패턴: 루트-루트-5도-루트
            pattern = [freq, freq, freq * 1.5, freq]

            for i, f in enumerate(pattern):
                velocity = 0.9 if i == 0 else 0.7
                wave = self.bass.finger_bass(f, beat_duration, velocity)
                bassline.append(wave)

        return np.concatenate(bassline)

    def generate_drum_pattern(self, bars: int = 4, style: str = 'rock') -> np.ndarray:
        """드럼 패턴 생성"""
        beat_samples = int(SAMPLE_RATE * self.beat_duration)
        bar_samples = beat_samples * 4
        total_samples = bar_samples * bars

        drums = np.zeros(total_samples)

        for bar in range(bars):
            bar_start = bar * bar_samples

            for beat in range(4):
                beat_start = bar_start + beat * beat_samples

                # 킥: 1, 3박
                if beat in [0, 2]:
                    kick = self.drums.kick()
                    end_idx = min(beat_start + len(kick), total_samples)
                    drums[beat_start:end_idx] += kick[:end_idx - beat_start]

                # 스네어: 2, 4박
                if beat in [1, 3]:
                    snare = self.drums.snare()
                    end_idx = min(beat_start + len(snare), total_samples)
                    drums[beat_start:end_idx] += snare[:end_idx - beat_start]

                # 하이햇: 8분음표
                for eighth in range(2):
                    hh_start = beat_start + eighth * (beat_samples // 2)
                    hihat = self.drums.hihat(velocity=0.6 if eighth == 0 else 0.4)
                    end_idx = min(hh_start + len(hihat), total_samples)
                    drums[hh_start:end_idx] += hihat[:end_idx - hh_start]

        return drums

    def compose(self, bars: int = 8, style: str = 'electronic') -> np.ndarray:
        """곡 작곡"""
        print(f"작곡 중... (BPM: {self.bpm}, 마디: {bars}, 스타일: {style})")

        # 코드 진행 선택
        progression = random.choice(PROGRESSIONS)
        print(f"코드 진행: {' -> '.join(progression)}")

        # 스케일 (메이저 스케일 예시)
        scale = ['C4', 'D4', 'E4', 'F4', 'G4', 'A4', 'B4', 'C5']

        bar_duration = self.beat_duration * 4
        total_duration = bar_duration * bars
        total_samples = int(SAMPLE_RATE * total_duration)

        # 각 트랙 생성
        print("드럼 트랙 생성...")
        drums = self.generate_drum_pattern(bars)

        print("베이스 트랙 생성...")
        bassline = self.generate_bassline(progression, bars)

        print("코드 트랙 생성...")
        chords = []
        for bar in range(bars):
            root = progression[bar % len(progression)]
            chord = self.generate_chord(root, 'major' if style == 'pop' else 'power',
                                        bar_duration, 'synth' if style == 'electronic' else 'guitar')
            chords.append(chord)
        chords = np.concatenate(chords)

        print("멜로디 트랙 생성...")
        melody = self.generate_melody(scale, bars,
                                       'synth' if style == 'electronic' else 'square')

        # 트랙 길이 맞추기
        def pad_to_length(arr: np.ndarray, length: int) -> np.ndarray:
            if len(arr) < length:
                return np.pad(arr, (0, length - len(arr)))
            return arr[:length]

        drums = pad_to_length(drums, total_samples)
        bassline = pad_to_length(bassline, total_samples)
        chords = pad_to_length(chords, total_samples)
        melody = pad_to_length(melody, total_samples)

        # 믹싱
        print("믹싱 중...")
        mix = (drums * 0.35 +
               bassline * 0.25 +
               chords * 0.25 +
               melody * 0.15)

        # 노멀라이즈
        max_val = np.max(np.abs(mix))
        if max_val > 0:
            mix = mix / max_val * 0.9

        return mix

    def save_wav(self, audio: np.ndarray, filename: str):
        """WAV 파일로 저장"""
        # 16비트 정수로 변환
        audio_int = (audio * 32767).astype(np.int16)
        wavfile.write(filename, SAMPLE_RATE, audio_int)
        print(f"저장 완료: {filename}")


def main():
    """메인 함수"""
    print("=" * 50)
    print("Electric Instrument Music Composer")
    print("전기 악기 음악 작곡 프로그램")
    print("=" * 50)

    # 작곡기 생성
    composer = MusicComposer(bpm=120)

    # 여러 스타일의 곡 생성
    styles = ['electronic', 'rock', 'pop']

    for style in styles:
        print(f"\n{'='*40}")
        print(f"스타일: {style.upper()}")
        print('='*40)

        # 곡 작곡
        music = composer.compose(bars=8, style=style)

        # WAV 파일로 저장
        filename = f"composed_music_{style}.wav"
        composer.save_wav(music, filename)

    print("\n" + "=" * 50)
    print("모든 곡 작곡 완료!")
    print("생성된 파일:")
    for style in styles:
        print(f"  - composed_music_{style}.wav")
    print("=" * 50)


if __name__ == "__main__":
    main()
