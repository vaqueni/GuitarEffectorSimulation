"""학습된 .nam 모델에 WAV를 통과시켜 결과를 저장한다 (PC 시뮬레이션)

입력 샘플레이트가 모델(48 kHz)과 다르면 48 kHz로 바꿔서 통과시킨 뒤 원래 샘플레이트로 되돌린다.
--ref로 같은 입력을 실제 페달에 통과시킨 녹음을 주면 지연을 맞춰 비교 수치도 출력한다.

사용법 (저장소 최상위 폴더에서):
    python nam/eval/simulate.py DATA/source/clean1.wav --gain -18 --match --ref DATA/janray/janray.wav
    python nam/eval/simulate.py DATA/source/clean1.wav --gain -18 --match --ref DATA/janray/janray.wav --size lite

결과는 따로 지정하지 않으면 nam/eval/<입력 이름>_nam[_lite].wav로 저장된다.
clean1.wav는 입력 게인 -18 dB에서 페달 녹음(janray.wav)과 가장 잘 맞는다 (2026-11-10 게인 스윕, ESR 0.006).
0 dB로 넣으면 페달보다 훨씬 세게 걸려서 ESR이 0.11까지 나빠진다.
"""

import argparse
import json
import sys
from fractions import Fraction
from pathlib import Path

import numpy as np
import soundfile as sf
import torch
from scipy.signal import resample_poly
from nam.models._from_nam import init_from_nam

ROOT = Path(__file__).resolve().parent.parent


def read_mono(path):
    x, sr = sf.read(path, always_2d=True, dtype="float64")
    return x[:, 0], sr


def load_model(path, size="full"):
    """.nam을 불러온다. 여러 크기가 들어 있는 파일(SlimmableContainer)이면 하나를 고른다.
    full = 8채널(큰 모델), lite = 3채널(작은 모델, Pi 4용 후보)"""
    cfg = json.loads(Path(path).read_text(encoding="utf-8"))
    sr = int(cfg.get("sample_rate") or 48000)
    if cfg["architecture"] == "SlimmableContainer":
        subs = sorted(cfg["config"]["submodels"], key=lambda s: s["max_value"])
        cfg = (subs[-1] if size == "full" else subs[0])["model"]
        sr = int(cfg.get("sample_rate") or sr)
    model = init_from_nam(cfg)
    model.eval()
    return model, sr


def resample(x, sr_from, sr_to):
    if sr_from == sr_to:
        return x
    r = Fraction(sr_to, sr_from)
    return resample_poly(x, r.numerator, r.denominator)


def run_model(model, msr, x, sr, gain_db=0.0):
    """x(sr)에 입력 게인을 걸고 모델(msr)에 통과시킨 뒤 sr로 되돌린다."""
    xm = resample(x * 10 ** (gain_db / 20), sr, msr)
    with torch.no_grad():
        y = model(torch.tensor(xm, dtype=torch.float32), pad_start=True).numpy().astype(np.float64)
    return resample(y, msr, sr)[:len(x)]


def compare(sim, ref, sr):
    """지연(+-50 ms)을 맞추고, 레벨 차이를 보정한 뒤 상관/ESR/대역별 차이를 구한다."""
    n = min(len(sim), len(ref))
    sim, ref = sim[:n], ref[:n]
    L = int(0.05 * sr)
    N = 1 << int(np.ceil(np.log2(2 * n)))
    c = np.fft.irfft(np.fft.rfft(ref, N) * np.conj(np.fft.rfft(sim, N)), N)
    cand = np.concatenate([c[-L:], c[:L + 1]])
    lag = int(np.argmax(np.abs(cand))) - L
    a, b = (sim[:n - lag], ref[lag:]) if lag >= 0 else (sim[-lag:], ref[:n + lag])
    corr = np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b) + 1e-12)
    g = np.dot(a, b) / (np.dot(a, a) + 1e-12)          # 레벨 차이는 볼륨 노브 차이로 보고 보정
    esr = np.sum((b - g * a) ** 2) / (np.sum(b ** 2) + 1e-12)

    def spec(s):
        f = np.fft.rfftfreq(8192, 1 / sr)
        frames = s[:len(s) // 8192 * 8192].reshape(-1, 8192) * np.hanning(8192)
        return f, 10 * np.log10(np.mean(np.abs(np.fft.rfft(frames)) ** 2, axis=0) + 1e-20)

    f, sa = spec(g * a)
    _, sb = spec(b)
    bands = [(80, 250), (250, 800), (800, 2500), (2500, 6000), (6000, 12000)]
    band_diff = [(lo, hi, float(np.mean(sa[(f >= lo) & (f < hi)] - sb[(f >= lo) & (f < hi)]))) for lo, hi in bands]
    return lag, corr, g, esr, band_diff


def db(v):
    return 20 * np.log10(v + 1e-12)


def main():
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    p = argparse.ArgumentParser()
    p.add_argument("input")
    p.add_argument("--model", default=str(ROOT / "models" / "janray.nam"))
    p.add_argument("--size", choices=["full", "lite"], default="full")
    p.add_argument("--out", help="저장 경로 (기본: eval/<이름>_nam[_lite].wav)")
    p.add_argument("--ref", help="같은 입력을 실제 페달에 통과시킨 녹음 (비교용)")
    p.add_argument("--gain", type=float, default=0.0,
                   help="모델에 넣기 전 입력 게인(dB). NAM 플러그인의 Input 노브와 같음")
    p.add_argument("--match", action="store_true",
                   help="--ref 녹음과 음량이 같아지도록 출력 레벨을 맞춘다 (Output 노브와 같음)")
    args = p.parse_args()

    x, sr = read_mono(args.input)
    model, msr = load_model(args.model, args.size)
    y = run_model(model, msr, x, sr, args.gain)

    ref = None
    if args.ref:
        r, rsr = read_mono(args.ref)
        ref = resample(r, rsr, sr)
    if args.match and ref is not None:
        g = compare(y, ref, sr)[2]
        y = y * abs(g)
        print(f"출력 레벨을 페달 녹음에 맞춤: {db(abs(g)):+.1f} dB")

    suffix = "_nam" if args.size == "full" else "_nam_lite"
    out = Path(args.out) if args.out else ROOT / "eval" / f"{Path(args.input).stem}{suffix}.wav"
    peak = np.abs(y).max()
    print(f"입력 {args.input} ({sr} Hz, {len(x) / sr:.2f}초, 피크 {db(np.abs(x).max()):.1f} dBFS, 입력 게인 {args.gain:+.1f} dB)")
    print(f"모델 {Path(args.model).name} ({args.size}, {msr} Hz)")
    print(f"출력 피크 {db(peak):.1f} dBFS, RMS {db(np.sqrt(np.mean(y ** 2))):.1f} dBFS")
    if peak >= 1.0:
        y = y / peak * 0.99
        print(f"  (0 dBFS를 넘어서 {db(peak):.1f} dB 줄여 저장)")
    sf.write(out, y, sr, subtype="PCM_24")
    print(f"저장: {out}")

    if ref is not None:
        lag, corr, g, esr, bands = compare(y, ref, sr)
        print()
        print(f"실제 페달 녹음과 비교: {args.ref}")
        print(f"  피크 NAM {db(np.abs(y).max()):.1f} / 페달 {db(np.abs(ref).max()):.1f} dBFS, "
              f"RMS NAM {db(np.sqrt(np.mean(y ** 2))):.1f} / 페달 {db(np.sqrt(np.mean(ref ** 2))):.1f} dBFS")
        print(f"  지연 {lag} 샘플, 상관 {corr:.3f}, 레벨 차이 {db(abs(g)):+.1f} dB 보정 후 ESR {esr:.3f}")
        for lo, hi, d in bands:
            print(f"  {lo:>5}-{hi:<5} Hz  NAM - 페달 {d:+.1f} dB")


if __name__ == "__main__":
    sys.exit(main())
