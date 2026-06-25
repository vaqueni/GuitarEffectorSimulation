# 🎸 Guitar Effector Simulation

기타 이펙터의 전달함수(Transfer Function)를 추정하고, 클린 기타 신호에 시뮬레이션하여 적용하는 DSP 프로젝트입니다.  
MATLAB과 Python을 함께 사용하며, JanRay 오버드라이브 페달과 Delay 이펙터를 주 분석 대상으로 합니다.

---

## 📌 프로젝트 개요

이 프로젝트는 다음 두 가지 이펙터를 시뮬레이션합니다:

| 이펙터 | 방식 | 구현 언어 |
|---|---|---|
| **JanRay Overdrive** | FFT 기반 전달함수 추정 후 새 신호에 적용 | MATLAB |
| **Delay** | BPM 동기화된 LTI 딜레이 필터 | Python |

---

## 🗂️ 프로젝트 구조

```
GuitarEffectorSimulation/
│
├── DATA/                        # 입력 오디오 데이터
│   ├── clean1.wav               # 클린 기타 신호 (학습용)
│   ├── clean2.wav               # 클린 기타 신호 (테스트용)
│   ├── janray.wav               # JanRay 이펙터 처리된 신호
│   ├── sine_440Hz.wav           # 440Hz 사인파
│   ├── impulse_response.wav     # 임펄스 신호
│   ├── gaussian_noise.wav       # 가우시안 노이즈
│   ├── sine_sweep.wav           # 사인 스윕 (20Hz~20kHz)
│   └── DELAY/                   # 딜레이 처리된 신호들
│
├── OUTPUT/                      # 출력 결과 저장 경로
│   └── DELAY/
│
├── main.m                       # 메인 실행 스크립트 (MATLAB)
├── estimate_transfer_function.m # 전달함수 추정 함수
├── apply_transfer_function.m    # 전달함수 적용 함수
├── compare_similarity.m         # 유사도 비교 스크립트
│
├── delay.py                     # Delay 이펙터 시뮬레이션 (Python)
├── osc.py                       # 테스트 신호 생성기 (사인파, 임펄스, 노이즈, 스윕)
├── osc_impulse.py               # 임펄스 신호 생성
├── osc_gnoise.py                # 가우시안 노이즈 생성
│
├── JanRayAnalysis.m             # JanRay 주파수 응답 비교 분석
├── guitar_analysis.m            # 기타 주파수 스펙트럼 분석
├── sine_analysis.m              # 사인파 주파수 분석
├── powerspectrum_guitar.m       # 기타 파워 스펙트럼
├── powerspectrum_sine.m         # 사인파 파워 스펙트럼 및 피크 검출
├── sin_janray.m                 # 사인파 → JanRay 비교
├── time_domain_compare.m        # 시간 영역 파형 비교
│
└── wav_similarity_ranking.csv   # 유사도 비교 결과
```

---

## ⚙️ 요구 환경

### MATLAB
- MATLAB R2020a 이상 권장
- Signal Processing Toolbox

### Python
- Python 3.8 이상
- `numpy`
- `scipy`

```bash
pip install numpy scipy
```

---

## 🚀 실행 방법

### 1. 테스트 신호 생성 (Python)

```bash
# 사인파, 임펄스, 가우시안 노이즈, 사인 스윕 생성
python osc.py

# 개별 생성
python osc_impulse.py
python osc_gnoise.py
```

생성된 WAV 파일을 `DATA/` 폴더에 위치시킵니다.

### 2. Delay 이펙터 적용 (Python)

```bash
python delay.py
```

`DATA/` 폴더의 입력 파일에 딜레이를 적용하여 `DATA/DELAY/`에 저장합니다.

주요 파라미터 (`delay.py` 내 직접 수정):

| 파라미터 | 기본값 | 설명 |
|---|---|---|
| `bpm` | 90.0 | 템포 (BPM) |
| `note` | `"eighth"` | 딜레이 음표 단위 |
| `mix` | 0.32 | 딜레이 믹스 비율 |
| `feedback` | 0.45 | 피드백 게인 |
| `repeats` | 7 | 반복 횟수 |

지원 note 종류: `whole`, `half`, `quarter`, `eighth`, `sixteenth`, `dotted_eighth`, `triplet_eighth`

### 3. 전달함수 추정 및 적용 (MATLAB)

`main.m`을 열고 `num` 값을 설정한 후 실행합니다.

```matlab
num = 7;  % 사용할 입력/출력 쌍 번호 (1~9)
```

| num | 입력 | 출력 (학습 타겟) |
|---|---|---|
| 1 | sine_440Hz | f(sine_440Hz) — JanRay 적용 |
| 2 | impulse_response | f(impulse_response) |
| 3 | gaussian_noise | f(gaussian_noise) |
| 4 | clean1 | janray |
| 5~9 | 딜레이 신호 쌍 | — |

실행하면:
1. 입력/출력 쌍으로부터 **전달함수 H(f)** 를 추정합니다.
2. 테스트 신호(`clean2.wav`)에 H(f)를 적용합니다.
3. 결과를 `OUTPUT/` 폴더에 저장합니다.

### 4. 유사도 평가 (MATLAB)

```matlab
% compare_similarity.m 실행
% refFile과 compareFiles를 직접 수정 후 실행
```

결과는 `wav_similarity_ranking.csv`에 저장되며 다음 지표를 포함합니다:

| 지표 | 설명 |
|---|---|
| Correlation | 시간 영역 상관계수 |
| NCC | 정규화 교차상관 |
| RMSE | 시간 영역 평균 제곱근 오차 |
| SpectralCosine | 주파수 영역 코사인 유사도 |
| LogSpectralRMSE | 로그 스펙트럼 RMSE (dB) |
| **SimilarityScore** | 통합 유사도 점수 (높을수록 유사) |

유사도 점수 가중치:
```
Score = 0.35 × Correlation + 0.35 × SpectralCosine
      + 0.15 × (1/(1+RMSE)) + 0.15 × (1/(1+LogSpectralRMSE))
```

---

## 📊 분석 스크립트

| 스크립트 | 설명 |
|---|---|
| `JanRayAnalysis.m` | Clean vs JanRay 주파수 응답 비교 |
| `sin_janray.m` | 사인파 기준 JanRay 전후 비교 (시간/주파수) |
| `guitar_analysis.m` | 게인별 기타 주파수 스펙트럼 비교 |
| `sine_analysis.m` | 게인별 사인파 주파수 분석 |
| `powerspectrum_guitar.m` | 기타 파워 스펙트럼 |
| `powerspectrum_sine.m` | 사인파 파워 스펙트럼 및 피크 검출 |
| `time_domain_compare.m` | 시간 영역 파형 시각화 |

---

## 🔬 핵심 알고리즘

### 전달함수 추정 (`estimate_transfer_function.m`)

1. xcorr로 시간 지연 보정
2. Hann 윈도우 적용 후 FFT
3. `H(f) = Y(f) / X(f)` (Tikhonov 정규화 포함)
4. Magnitude smoothing (이동 평균)
5. 최대 게인 제한 (8배)

### 전달함수 적용 (`apply_transfer_function.m`)

1. 입력 신호 FFT
2. H(f) 보간 후 주파수 영역 곱셈
3. IFFT로 시간 영역 복원
4. Peak normalization (0.95)

### Delay 이펙터 (`delay.py`)

BPM 기반 LTI 딜레이:

```
y[n] = dry_gain × x[n] + Σ (mix × feedback^(k-1)) × x[n - k×D]
```

- `D`: BPM과 음표로 계산된 딜레이 샘플 수
- `k`: 1 ~ repeats

---

## 📁 데이터 파일 규칙

| 접두사 | 의미 |
|---|---|
| `c_` | clean 기타 신호 |
| `s_` | sine wave |
| `i_` | impulse |
| `g_` | gaussian noise |
| `ss_` | sine sweep |
| `f(...)` | JanRay 이펙터 적용 신호 |
| `*_delay` | Delay 이펙터 적용 신호 |
| `*_output` | 전달함수 시뮬레이션 결과 |
