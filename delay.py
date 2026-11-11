import os
import numpy as np
from scipy.io import wavfile


def read_wav_mono(path: str):
    fs, x = wavfile.read(path)

    if x.ndim == 2:
        x = x.mean(axis=1)

    if np.issubdtype(x.dtype, np.integer):
        max_int = np.iinfo(x.dtype).max
        x = x.astype(np.float32) / max_int
    else:
        x = x.astype(np.float32)

    return fs, x


def write_wav(path: str, fs: int, x: np.ndarray):
    x = np.asarray(x, dtype=np.float32)

    peak = np.max(np.abs(x))
    if peak > 1.0:
        x = x / peak * 0.98

    wavfile.write(path, fs, (x * 32767).astype(np.int16))


def bpm_to_delay_samples(fs: int, bpm: float, note: str = "quarter") -> int:
    quarter_sec = 60.0 / bpm

    note_map = {
        "whole": 4.0,
        "half": 2.0,
        "quarter": 1.0,
        "eighth": 0.5,
        "sixteenth": 0.25,
        "dotted_eighth": 0.75,
        "triplet_eighth": 1.0 / 3.0,
    }

    if note not in note_map:
        raise ValueError(f"Unsupported note: {note}")

    delay_sec = quarter_sec * note_map[note]
    return int(round(delay_sec * fs))


def apply_guitar_delay_lti(
    x: np.ndarray,
    fs: int,
    bpm: float,
    note: str = "dotted_eighth",
    mix: float = 0.35,
    feedback: float = 0.40,
    repeats: int = 6,
    dry_gain: float = 1.0,
):
    if not (0.0 <= mix <= 1.0):
        raise ValueError("mix must be between 0 and 1")
    if not (0.0 <= feedback < 1.0):
        raise ValueError("feedback must be in [0, 1)")
    if repeats < 1:
        raise ValueError("repeats must be >= 1")

    delay_samples = bpm_to_delay_samples(fs, bpm, note)

    out_len = len(x) + delay_samples * repeats
    y = np.zeros(out_len, dtype=np.float32)

    y[:len(x)] += dry_gain * x

    for k in range(1, repeats + 1):
        gain = mix * (feedback ** (k - 1))
        start = k * delay_samples
        end = start + len(x)
        y[start:end] += gain * x

    return y, delay_samples


if __name__ == "__main__":
    input_shortcut = "DATA/source/"
    output_shortcut = "DATA/delay/"

    input_files = [
#        
#         "sine_440Hz.wav",
#         "impulse_response.wav",
#         "gaussian_noise.wav",
#         "clean1.wav",
# 
        # "clean2.wav"
        # "sine_sweep.wav"
            ]

    output_files = [
#
        # "s_delay.wav",
        # "i_delay.wav",
        # "g_delay.wav",
        # "c_delay.wav",
#
        # "ss_delay.wav"
    ]

    os.makedirs(output_shortcut, exist_ok=True)

    bpm = 90.0
    note = "eighth"
    mix = 0.32
    feedback = 0.45
    repeats = 7
    dry_gain = 1.0

    for input_file, output_file in zip(input_files, output_files):
        input_path = os.path.join(input_shortcut, input_file)
        output_path = os.path.join(output_shortcut, output_file)

        fs, x = read_wav_mono(input_path)

        y, delay_samples = apply_guitar_delay_lti(
            x=x,
            fs=fs,
            bpm=bpm,
            note=note,
            mix=mix,
            feedback=feedback,
            repeats=repeats,
            dry_gain=dry_gain,
        )

        write_wav(output_path, fs, y)

        delay_ms = 1000.0 * delay_samples / fs
        print(f"Saved: {output_path}")
        print(f"BPM: {bpm}")
        print(f"Note: {note}")
        print(f"Delay: {delay_samples} samples ({delay_ms:.2f} ms)")
        print("-" * 40)