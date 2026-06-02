sin = 'DATA/sine_440Hz.wav'
f_sin = 'DATA/f(sine_440Hz).wav'


% wav 읽기
[x, fs] = audioread(sin);
[y, ~]  = audioread(f_sin);


% 길이 맞추기
N = min(length(x), length(y));
x = x(1:N);
y = y(1:N) ;

% FFT
X = fft(x);
Y = fft(y);

% H(f) 계산
eps = 1e-10;
H = Y ./ (X + eps);

% 주파수 축
f = (0:N-1)*(fs/N);

% magnitude (dB)
%X_mag = 20*log10(abs(X) + 1e-12);
%Y_mag = 20*log10(abs(Y) + 1e-12);
X_mag = X;
Y_mag = Y;
%plot (양수 주파수만)
half = floor(N/2);
% 아래과정을 진행함으로서 구간별 평균값을 표기해서 smooth한 그래프를 출력한다.
window_size = 200;
% H_smooth = sgolayfilt(H_mag,3,201);
X_smooth = movmean(X_mag, window_size);
%Y_smooth = movmean(Y_mag, window_size);
figure;

% clean (파란색)
plot(f(1:half), X_smooth(1:half), 'b')
hold on

% janray (빨강)
plot(f(1:half), Y_smooth(1:half), 'r', 'LineWidth', 2)
xlim([0 2000])
xlabel('Frequency (Hz)')
ylabel('Magnitude (dB)')
title('Frequency Response Comparison')
legend('sin', 'JanRay sin')
grid on

t = (0:N-1) / fs;

% 플롯
figure;
plot(t, x, 'b');
hold on;
plot(t, y, 'r');

xlabel('Time (seconds)');
ylabel('Amplitude');
title('Time Domain Signal Comparison');
legend('Original', 'Processed');
xlim([0 0.04])
grid on;