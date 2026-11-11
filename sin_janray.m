sin = 'DATA/source/sine_440Hz.wav'
f_sin = 'DATA/janray/f(sine_440Hz).wav'


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

%plot (양수 주파수만)
half = floor(N/2);

% magnitude (dB)
% 배음 피크가 뭉개지지 않도록 이동평균 대신 Hann 윈도우를 씌워 FFT하고,
% 각 신호의 가장 큰 피크(440Hz 기본음)를 0dB로 맞춰 배음이 기본음보다 몇 dB 작은지 보이게 한다.
w = hann(N);
X_win = abs(fft(x(:) .* w));
Y_win = abs(fft(y(:) .* w));
X_mag = 20*log10(X_win / max(X_win(1:half)) + 1e-12);
Y_mag = 20*log10(Y_win / max(Y_win(1:half)) + 1e-12);

f0 = 440;
n_harm = 6;
figure;

% janray (빨강) — 원신호가 가려지지 않도록 먼저 그린다
h_y = plot(f(1:half), Y_mag(1:half), 'r', 'LineWidth', 1.2);
hold on

% clean (파란색)
h_x = plot(f(1:half), X_mag(1:half), 'b');

% 배음 위치 표시 (2f0, 3f0, ...)
for k = 2:n_harm
    xline(k*f0, 'k:', sprintf('%df_0', k), 'HandleVisibility', 'off');
end

xlim([0 (n_harm+0.5)*f0])
ylim([-140 10])
xlabel('Frequency (Hz)')
ylabel('Magnitude (dB, 기본음 = 0dB)')
title('440Hz Sine: JanRay가 만든 배음')
legend([h_x h_y], {'sin', 'JanRay sin'}, 'Location', 'southoutside', 'Orientation', 'horizontal')
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