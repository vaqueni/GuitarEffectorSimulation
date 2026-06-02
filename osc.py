import numpy as np
from scipy.io.wavfile import write
from scipy.signal import chirp


# 공통 설정
fs = 44100          # 샘플링 레이트 (Hz)
duration = 5        # 길이 (초)
t = np.linspace(0, duration, int(fs * duration), endpoint=False)


# 1. 440Hz Sine 파
def sin_Hz(Hz):
    sine_wave = 0.5 * np.sin(2 * np.pi * Hz * t)
    write(f"sine_{Hz}Hz.wav", fs, (sine_wave * 32767).astype(np.int16))


# 2. Impulse response
def impulse():
    impulse_signal = np.zeros(int(fs * duration))
    impulse_signal[10] = 1.0
    write("impulse_response.wav", fs, (impulse_signal * 32767).astype(np.int16))


# 3. 가우시안 노이즈
def gNoise():
    noise = np.random.normal(0, 0.2, int(fs * duration))
    write("gaussian_noise.wav", fs, (noise * 32767).astype(np.int16))


# 4. Sine Sweep
def sineSweep(f_start=20, f_end=20000):
    sweep = chirp(
        t,
        f0=f_start,
        f1=f_end,
        t1=duration,
        method="logarithmic"
    )

    # Fade In / Out
    fade_time = 0.01
    fade_samples = int(fs * fade_time)

    fade_in = np.linspace(0, 1, fade_samples)
    fade_out = np.linspace(1, 0, fade_samples)

    sweep[:fade_samples] *= fade_in
    sweep[-fade_samples:] *= fade_out

    # Normalize
    sweep = sweep / np.max(np.abs(sweep))
    sweep = 0.95 * sweep

    write(
        f"sine_sweep_{f_start}Hz_to_{f_end}Hz.wav",
        fs,
        (sweep * 32767).astype(np.int16)
    )


# 실행
#sin_Hz(440)
#impulse()
#gNoise()
sineSweep()

print("WAV 파일 생성 완료")