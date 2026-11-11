import wave

def wav_info(path):
    with wave.open(path, "rb") as w:
        sr = w.getframerate()        # 샘플레이트
        ch = w.getnchannels()        # 채널 수
        bits = w.getsampwidth() * 8  # 비트 깊이
        frames = w.getnframes()      # 총 샘플 수
    print(f"{path}: {sr} Hz, {ch}ch, {bits}-bit, {frames} frames ({frames / sr:.2f}초)")

for p in ["capture/input.wav", "capture/output_fixed.wav"]:
    wav_info(p)