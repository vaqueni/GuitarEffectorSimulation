# train_nam.py
from pathlib import Path

from nam.train import core
from nam.train import metadata

INPUT = "capture/input.wav"
OUTPUT = "capture/output_fixed.wav"
TRAIN_DIR = Path("runs")      # 학습 중 체크포인트와 로그가 쌓이는 곳
EXPORT_DIR = Path("models")   # 최종 .nam 파일이 저장될 곳
NAME = "janray"


def main():
    TRAIN_DIR.mkdir(exist_ok=True)
    EXPORT_DIR.mkdir(exist_ok=True)

    # 학습: f(input) ≈ output 이 되도록 신경망을 맞춤
    out = core.train(
        INPUT,
        OUTPUT,
        str(TRAIN_DIR),
        epochs=100,
        save_plot=True,   # 예측 vs 실제 파형 그래프 저장
        modelname=NAME,
        local=True,       # GUI 트레이너와 같은 설정 (내 PC에서 실행)
    )

    if out is None or out.model is None:
        print("학습 실패: 위쪽 로그의 데이터 체크 메시지를 확인하세요.")
        return

    # 학습된 함수를 .nam 파일로 내보내기
    out.model.net.export(
        EXPORT_DIR,
        basename=NAME,
        other_metadata={metadata.TRAINING_KEY: out.metadata.model_dump()},
    )
    print(f"완료: {EXPORT_DIR / (NAME + '.nam')}")


if __name__ == "__main__":   # Windows에서는 이 줄이 꼭 있어야 함
    main()