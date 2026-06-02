import numpy as np
from scipy.io.wavfile import write

# 설정
fs = 44100          # 샘플레이트
duration = 3.0      # 초
std = 0.1           # 노이즈 세기(표준편차)

# 가우시안 노이즈 생성
num_samples = int(fs * duration)
noise = np.random.normal(0, std, num_samples)

# WAV 저장용 정규화
noise = np.clip(noise, -1.0, 1.0)
noise_int16 = np.int16(noise * 32767)

# 저장
write("gaussian_noise.wav", fs, noise_int16)

print("gaussian_noise.wav 저장 완료")