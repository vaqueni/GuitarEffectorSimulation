import numpy as np
from scipy.io.wavfile import write

# 설정
fs = 44100
duration = 1.0
impulse_position = 1   # 0이면 맨 처음 샘플에 임펄스
amplitude = 1.0

# 임펄스 생성
num_samples = int(fs * duration)
impulse = np.zeros(num_samples, dtype=np.float32)
impulse[impulse_position] = amplitude

# int16 변환 후 저장
impulse_int16 = np.int16(impulse * 32767)

write("impulse.wav", fs, impulse_int16)

print("impulse.wav 저장 완료")