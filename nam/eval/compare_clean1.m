% compare_clean1.m
% 시뮬레이션된 clean1(NAM full / lite)과 실제 잔레이 페달 녹음의 차이를 측정한다.
%
% 입력: nam/eval의 clean1_nam.wav, clean1_nam_lite.wav, clean1_nomrstft.wav, clean1_nomrstft_lite.wav
%       DATA/janray/janray.wav (실제 페달), DATA/source/clean1.wav (기준선)
%       1단계 전달함수 비교용: DATA/source, DATA/janray의 원신호와 통과 신호
% 출력: 콘솔 수치, compare_clean1.png, compare_nomrstft.png
%
% 순서: 지연 정렬(정수 + 소수 샘플) -> 레벨 보정 -> ESR/대역/코히어런스/시간 분석
% 레벨 보정은 최소제곱 게인 하나만 쓴다 (볼륨 노브 차이로 간주).
% 경로는 이 파일 위치 기준이라 어느 폴더에서 실행해도 된다.

here = fileparts(mfilename('fullpath'));
root = fullfile(here, '..', '..');
[pedal, fs] = readMono(fullfile(root, 'DATA', 'janray', 'janray.wav'));
[dry, fsDry] = readMono(fullfile(root, 'DATA', 'source', 'clean1.wav'));
assert(fsDry == fs, 'clean1.wav sample rate differs');

names = {'NAM full', 'NAM lite', 'Dry DI', 'no-MRSTFT full', 'no-MRSTFT lite'};
files = {fullfile(here, 'clean1_nam.wav'), fullfile(here, 'clean1_nam_lite.wav'), ...
    fullfile(root, 'DATA', 'source', 'clean1.wav'), ...
    fullfile(here, 'clean1_nomrstft.wav'), fullfile(here, 'clean1_nomrstft_lite.wav')};
bands = [20 80; 80 250; 250 800; 800 2500; 2500 6000; 6000 12000; 12000 fs/2];
nb = size(bands, 1);
R = struct();

fprintf('fs = %d Hz, pedal %.3f s, peak %.2f dBFS, RMS %.2f dBFS\n', ...
    fs, numel(pedal)/fs, db20(max(abs(pedal))), db20(rms(pedal)));

for k = 1:numel(names)
    [s, fsS] = readMono(files{k});
    assert(fsS == fs, '%s sample rate differs', files{k});
    r = analyzePair(s, pedal, fs, bands);
    R(k).name = names{k};
    fn = fieldnames(r);
    for i = 1:numel(fn)
        R(k).(fn{i}) = r.(fn{i});
    end

    fprintf('\n=== %s vs pedal ===\n', names{k});
    fprintf('peak %.2f dBFS, RMS %.2f dBFS, crest %.2f dB\n', ...
        db20(max(abs(s))), db20(rms(s)), db20(max(abs(s))/rms(s)));
    fprintf('lag int %d samples (%.3f ms), frac %+.3f samples, polarity %+d\n', ...
        r.lag, 1000*r.lag/fs, r.frac, sign(r.g));
    fprintf('LS gain %+.3f dB\n', db20(abs(r.g)));
    fprintf('corr %.5f\n', r.corr);
    fprintf('ESR no-gain %.5f | int-lag only %.5f | frac+gain %.5f (null %.2f dB)\n', ...
        r.esrRaw, r.esrInt, r.esr, -10*log10(r.esr));
    fprintf('ESR pre-emphasis (1-0.95z^-1) %.5f\n', r.esrPre);
    fprintf('drift: %.4f samples/s over %d voiced segments, lag range %.3f..%.3f\n', ...
        r.driftSlope, numel(r.segLag), min(r.segLag), max(r.segLag));
    fprintf('segment ESR median %.5f, worst %.5f at %.2f s\n', ...
        median(r.segEsr), max(r.segEsr), r.segT(find(r.segEsr == max(r.segEsr), 1)));
    fprintf('short-time RMS (sim-pedal): loud 10%% %+.2f dB, quiet 10%% %+.2f dB\n', ...
        r.loudDiff, r.quietDiff);
    fprintf('ESR by loudness: loud 10%% %.5f, quiet 10%% %.5f\n', r.loudEsr, r.quietEsr);
    fprintf('%14s %10s %10s %10s %10s\n', 'band Hz', 'share %', 'diff dB', 'bandESR', 'coh');
    for b = 1:nb
        fprintf('%6.0f-%-7.0f %10.3f %+10.2f %10.4f %10.4f\n', bands(b, 1), bands(b, 2), ...
            100*r.bandShare(b), r.bandDiff(b), r.bandEsr(b), r.bandCoh(b));
    end
end

% 1/6 옥타브 곡선에서 읽은 주파수별 차이 (시뮬레이션 - 페달)
probes = [3000 6000 10000 15000 20000];
fprintf('\n=== 1/6-octave difference vs pedal (dB) ===\n%-16s', '');
fprintf('%9.0f', probes);
fprintf('\n');
for k = [1 4 2 5]
    [fc, Sb] = smoothOct(R(k).fP, R(k).Pb, 6);
    [~, Sa] = smoothOct(R(k).fP, R(k).Pa, 6);
    fprintf('%-16s', R(k).name);
    fprintf('%+9.2f', interp1(fc, Sa - Sb, probes, 'linear', 'extrap'));
    fprintf('\n');
end

% 1단계 전달함수 방식(estimate_transfer_function / apply_transfer_function)을
% 같은 clean1에 적용해서 같은 지표로 비교한다.
% 마지막 항목은 clean1 자신으로 추정한 H라서, 같은 데이터로 평가한 선형 모델의 최선에 가깝다.
addpath(root);
ltiNames = {'H from sine', 'H from impulse', 'H from noise', 'H from clean1 (same data)'};
ltiPairs = {
    'sine_440Hz.wav', 'f(sine_440Hz).wav'
    'impulse_response.wav', 'f(impulse_response).wav'
    'gaussian_noise.wav', 'f(gaussian_noise).wav'
    'clean1.wav', 'janray.wav'
    };
ltiEsr = zeros(numel(ltiNames), 1);
fprintf('\n=== stage 1 transfer function applied to clean1 vs pedal ===\n');
fprintf('%-28s %9s %9s %10s %10s\n', 'H estimated from', 'corr', 'ESR', '6-12k dB', '12k+ dB');
for k = 1:numel(ltiNames)
    [xi, f1] = readMono(fullfile(root, 'DATA', 'source', ltiPairs{k, 1}));
    [yi, f2] = readMono(fullfile(root, 'DATA', 'janray', ltiPairs{k, 2}));
    assert(f1 == fs && f2 == fs, '%s sample rate differs', ltiPairs{k, 1});
    H = estimate_transfer_function(xi, yi, fs, false);
    r = analyzePair(apply_transfer_function(dry, H), pedal, fs, bands);
    ltiEsr(k) = r.esr;
    fprintf('%-28s %9.4f %9.4f %+10.2f %+10.2f\n', ltiNames{k}, r.corr, r.esr, r.bandDiff(6), r.bandDiff(7));
end

fprintf('\n=== ESR summary (lower = closer to the pedal) ===\n');
fprintf('%-28s %9.5f\n', R(3).name, R(3).esr);
for k = 1:numel(ltiNames)
    fprintf('%-28s %9.5f\n', ltiNames{k}, ltiEsr(k));
end
for k = [1 2 4 5]
    fprintf('%-28s %9.5f\n', R(k).name, R(k).esr);
end

plotAll(R, fs, bands);
plotMrstft(R, bands);
fprintf('\nsaved %s\n', fullfile(here, 'compare_clean1.png'));
fprintf('saved %s\n', fullfile(here, 'compare_nomrstft.png'));


function [x, fs] = readMono(p)
    [x, fs] = audioread(p, 'double');
    x = x(:, 1);
end

function y = db20(v)
    y = 20*log10(v + 1e-12);
end

function y = fracShift(x, d)
    % d > 0 이면 x를 d 샘플 늦춘다 (주파수 영역 위상 회전, 양 끝 순환 방지용 패딩)
    n = numel(x);
    N = 2^nextpow2(n + 2048);
    k = (0:N-1)';
    k(k > N/2) = k(k > N/2) - N;
    Y = fft(x, N) .* exp(-1i*2*pi*k*d/N);
    y = ifft(Y, 'symmetric');
    y = y(1:n);
end

function e = esrLS(a, b)
    g = dot(a, b)/dot(a, a);
    e = sum((b - g*a).^2)/sum(b.^2);
end

function y = bandMask(x, fs, lo, hi)
    N = numel(x);
    X = fft(x);
    f = (0:N-1)'*fs/N;
    f = min(f, fs - f);
    X(f < lo | f >= hi) = 0;
    y = real(ifft(X));
end

function r = analyzePair(sim, ref, fs, bands)
    n = min(numel(sim), numel(ref));
    sim = sim(1:n);
    ref = ref(1:n);

    L = round(0.05*fs);
    [c, lags] = xcorr(ref, sim, L);
    [~, i] = max(abs(c));
    lag = lags(i);
    if lag >= 0
        a = sim(1:n-lag);
        b = ref(1+lag:n);
    else
        a = sim(1-lag:n);
        b = ref(1:n+lag);
    end
    esrInt = esrLS(a, b);

    frac = fminbnd(@(d) esrLS(fracShift(a, d), b), -1.5, 1.5, optimset('TolX', 1e-3));
    a = fracShift(a, frac);
    edge = 256;                                    % 소수 지연 필터의 양 끝 제외
    a = a(edge+1:end-edge);
    b = b(edge+1:end-edge);

    g = dot(a, b)/dot(a, a);
    res = b - g*a;
    r.lag = lag;
    r.frac = frac;
    r.g = g;
    r.corr = dot(a, b)/(norm(a)*norm(b));
    r.esrRaw = sum((b - a).^2)/sum(b.^2);
    r.esrInt = esrInt;
    r.esr = sum(res.^2)/sum(b.^2);
    pe = [1 -0.95];
    r.esrPre = esrLS(filter(pe, 1, a), filter(pe, 1, b));
    r.a = g*a;
    r.b = b;
    r.res = res;

    % 대역별: 페달 에너지 비중, 레벨 차이, 잔차 비율
    nb = size(bands, 1);
    r.bandShare = zeros(nb, 1);
    r.bandDiff = zeros(nb, 1);
    r.bandEsr = zeros(nb, 1);
    r.bandCoh = zeros(nb, 1);
    win = hann(8192, 'periodic');
    [Cxy, fC] = mscohere(g*a, b, win, 6144, 8192, fs);
    for k = 1:nb
        ab = bandMask(g*a, fs, bands(k, 1), bands(k, 2));
        bb = bandMask(b, fs, bands(k, 1), bands(k, 2));
        r.bandShare(k) = sum(bb.^2)/sum(b.^2);
        r.bandDiff(k) = 10*log10(sum(ab.^2)/sum(bb.^2));
        r.bandEsr(k) = sum((bb - ab).^2)/sum(bb.^2);
        m = fC >= bands(k, 1) & fC < bands(k, 2);
        r.bandCoh(k) = mean(Cxy(m));
    end
    r.fC = fC;
    r.coh = Cxy;
    [r.Pa, r.fP] = pwelch(g*a, win, 6144, 8192, fs);
    r.Pb = pwelch(b, win, 6144, 8192, fs);

    % 0.5초 구간별 ESR과 지연 (드리프트 확인). 소리가 있는 구간만 쓴다.
    seg = round(0.5*fs);
    ns = floor(numel(b)/seg);
    rmsAll = rms(b);
    segT = [];
    segEsr = [];
    segLag = [];
    for k = 1:ns
        idx = (k-1)*seg + (1:seg);
        if rms(b(idx)) < 0.1*rmsAll
            continue
        end
        [cs, ls] = xcorr(b(idx), g*a(idx), 8);
        [~, j] = max(cs);
        d = 0;
        if j > 1 && j < numel(cs)
            d = 0.5*(cs(j-1) - cs(j+1))/(cs(j-1) - 2*cs(j) + cs(j+1));
        end
        segT(end+1) = (k - 0.5)*0.5; %#ok<AGROW>
        segEsr(end+1) = esrLS(a(idx), b(idx)); %#ok<AGROW>
        segLag(end+1) = ls(j) + d; %#ok<AGROW>
    end
    r.segT = segT;
    r.segEsr = segEsr;
    r.segLag = segLag;
    p = polyfit(segT, segLag, 1);
    r.driftSlope = p(1);

    % 짧은 구간 RMS (약 23 ms)
    fl = 1024;
    hop = 256;
    nf = floor((numel(b) - fl)/hop) + 1;
    ea = zeros(nf, 1);
    eb = zeros(nf, 1);
    er = zeros(nf, 1);
    for k = 1:nf
        idx = (k-1)*hop + (1:fl);
        ea(k) = mean((g*a(idx)).^2);
        eb(k) = mean(b(idx).^2);
        er(k) = mean(res(idx).^2);
    end
    r.tF = ((0:nf-1)*hop + fl/2)/fs;
    r.eb = eb;
    r.er = er;
    q = prctile(eb, [10 90]);
    quiet = eb <= q(1);
    loud = eb >= q(2);
    r.quietDiff = 10*log10(sum(ea(quiet))/sum(eb(quiet)));
    r.loudDiff = 10*log10(sum(ea(loud))/sum(eb(loud)));
    r.quietEsr = sum(er(quiet))/sum(eb(quiet));
    r.loudEsr = sum(er(loud))/sum(eb(loud));
end

function [fc, S] = smoothOct(f, P, frac)
    % 1/frac 옥타브 평균 (전력 평균 후 dB)
    fc = logspace(log10(30), log10(20000), 240)';
    S = zeros(size(fc));
    for k = 1:numel(fc)
        m = f >= fc(k)*2^(-1/(2*frac)) & f < fc(k)*2^(1/(2*frac));
        if ~any(m)
            [~, j] = min(abs(f - fc(k)));
            m(j) = true;
        end
        S(k) = 10*log10(mean(P(m)) + 1e-30);
    end
end

function styleAx(ax)
    ink = hex('#52514e');
    ax.Color = hex('#fcfcfb');
    ax.XColor = ink;
    ax.YColor = ink;
    ax.GridColor = hex('#e1e0d9');
    ax.GridAlpha = 1;
    ax.MinorGridColor = hex('#e1e0d9');
    ax.MinorGridAlpha = 1;
    ax.XGrid = 'on';
    ax.YGrid = 'on';
    ax.Box = 'off';
    ax.TickDir = 'out';
    ax.TickLength = [0.006 0.006];
    ax.FontName = 'Malgun Gothic';
    ax.FontSize = 11;
    ax.LineWidth = 0.75;
    ax.Title.FontWeight = 'bold';
    ax.Title.FontSize = 13;
    ax.Title.Color = hex('#0b0b0b');
    ax.TitleHorizontalAlignment = 'left';
end

function c = hex(h)
    c = sscanf(h(2:end), '%2x%2x%2x', [1 3])/255;
end

function freqAxis(ax)
    ax.XScale = 'log';
    ax.XLim = [30 20000];
    ax.XTick = [50 100 200 500 1000 2000 5000 10000 20000];
    ax.XTickLabel = {'50', '100', '200', '500', '1k', '2k', '5k', '10k', '20k'};
    ax.XMinorGrid = 'off';
    xlabel(ax, '주파수 (Hz)');
end

function plotAll(R, fs, bands)
    cFull = hex('#2a78d6');
    cPedal = hex('#eb6834');
    cLite = hex('#1baf7a');
    lw = 1.5;

    fig = figure('Visible', 'off', 'Color', hex('#fcfcfb'), 'Units', 'pixels', 'Position', [0 0 1500 1250]);
    tl = tiledlayout(fig, 3, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
    full = R(1);
    lite = R(2);

    % 1. 가장 큰 구간의 파형
    ax = nexttile(tl);
    [~, i] = max(full.eb);
    c0 = round(full.tF(i)*fs);
    idx = max(1, c0 - round(0.01*fs)):min(numel(full.b), c0 + round(0.01*fs));
    t = (idx - idx(1))/fs*1000;
    plot(ax, t, full.b(idx), 'Color', cPedal, 'LineWidth', lw, 'DisplayName', '실제 페달');
    hold(ax, 'on');
    plot(ax, t, full.a(idx), 'Color', cFull, 'LineWidth', lw, 'DisplayName', 'NAM full');
    title(ax, sprintf('파형 겹침 (가장 큰 구간, %.2f초 부근)', full.tF(i)));
    xlabel(ax, '시간 (ms)');
    ylabel(ax, '진폭');
    styleAx(ax);
    legend(ax, 'Location', 'northeast', 'Box', 'off');

    % 2. 시간에 따른 레벨과 잔차
    ax = nexttile(tl);
    plot(ax, full.tF, 10*log10(full.eb + 1e-14), 'Color', cPedal, 'LineWidth', lw, 'DisplayName', '페달 레벨');
    hold(ax, 'on');
    plot(ax, full.tF, 10*log10(full.er + 1e-14), 'Color', cFull, 'LineWidth', lw, 'DisplayName', '잔차 (full)');
    plot(ax, lite.tF, 10*log10(lite.er + 1e-14), 'Color', cLite, 'LineWidth', lw, 'DisplayName', '잔차 (lite)');
    title(ax, '시간에 따른 페달 레벨과 잔차');
    xlabel(ax, '시간 (초)');
    ylabel(ax, 'RMS (dBFS)');
    xlim(ax, [0 10]);
    styleAx(ax);
    legend(ax, 'Location', 'southeast', 'Box', 'off', 'Orientation', 'horizontal');

    % 3. 평균 스펙트럼
    ax = nexttile(tl);
    [fc, Sb] = smoothOct(full.fP, full.Pb, 6);
    [~, Sa] = smoothOct(full.fP, full.Pa, 6);
    [~, Sl] = smoothOct(lite.fP, lite.Pa, 6);
    semilogx(ax, fc, Sb, 'Color', cPedal, 'LineWidth', lw, 'DisplayName', '실제 페달');
    hold(ax, 'on');
    semilogx(ax, fc, Sa, 'Color', cFull, 'LineWidth', lw, 'DisplayName', 'NAM full');
    semilogx(ax, fc, Sl, 'Color', cLite, 'LineWidth', lw, 'DisplayName', 'NAM lite');
    title(ax, '평균 스펙트럼 (1/6 옥타브)');
    ylabel(ax, 'PSD (dB/Hz)');
    styleAx(ax);
    freqAxis(ax);
    legend(ax, 'Location', 'southwest', 'Box', 'off');

    % 4. 스펙트럼 차이
    ax = nexttile(tl);
    yline(ax, 0, 'Color', hex('#c3c2b7'), 'LineWidth', 1, 'HandleVisibility', 'off');
    hold(ax, 'on');
    semilogx(ax, fc, Sa - Sb, 'Color', cFull, 'LineWidth', lw, 'DisplayName', 'NAM full');
    semilogx(ax, fc, Sl - Sb, 'Color', cLite, 'LineWidth', lw, 'DisplayName', 'NAM lite');
    title(ax, '스펙트럼 차이 (시뮬레이션 - 페달)');
    ylabel(ax, '차이 (dB)');
    styleAx(ax);
    freqAxis(ax);
    legend(ax, 'Location', 'northwest', 'Box', 'off');

    % 5. 코히어런스
    ax = nexttile(tl);
    semilogx(ax, full.fC(2:end), full.coh(2:end), 'Color', cFull, 'LineWidth', lw, 'DisplayName', 'NAM full');
    hold(ax, 'on');
    semilogx(ax, lite.fC(2:end), lite.coh(2:end), 'Color', cLite, 'LineWidth', lw, 'DisplayName', 'NAM lite');
    title(ax, '코히어런스 (1에 가까울수록 선형적으로 일치)');
    ylabel(ax, '코히어런스');
    ylim(ax, [0 1.02]);
    styleAx(ax);
    freqAxis(ax);
    legend(ax, 'Location', 'southwest', 'Box', 'off');

    % 6. 대역별 잔차 비율
    ax = nexttile(tl);
    nb = size(bands, 1);
    yline(ax, 0, 'Color', hex('#c3c2b7'), 'LineWidth', 1, 'HandleVisibility', 'off');
    hold(ax, 'on');
    plot(ax, 1:nb, 10*log10(full.bandEsr), '-o', 'Color', cFull, 'MarkerFaceColor', cFull, ...
        'MarkerSize', 8, 'LineWidth', lw, 'DisplayName', 'NAM full');
    plot(ax, 1:nb, 10*log10(lite.bandEsr), '-o', 'Color', cLite, 'MarkerFaceColor', cLite, ...
        'MarkerSize', 8, 'LineWidth', lw, 'DisplayName', 'NAM lite');
    title(ax, '대역별 잔차 비율 (0 dB = 잔차가 페달만큼 큼)');
    ylabel(ax, '10·log_{10}(ESR) (dB)');
    xlabel(ax, '대역 (Hz)');
    styleAx(ax);
    ax.XTick = 1:nb;
    ax.XTickLabel = arrayfun(@(lo, hi) sprintf('%s-%s', kfmt(lo), kfmt(hi)), bands(:, 1), bands(:, 2), 'UniformOutput', false);
    ax.XLim = [0.6 nb + 0.4];
    legend(ax, 'Location', 'northwest', 'Box', 'off');

    here = fileparts(mfilename('fullpath'));
    exportgraphics(fig, fullfile(here, 'compare_clean1.png'), 'Resolution', 110, 'BackgroundColor', hex('#fcfcfb'));
    close(fig);
end

function plotMrstft(R, bands)
    % 현재 모델과 no-MRSTFT 모델 비교. 왼쪽 열 full, 오른쪽 열 lite
    cCur = hex('#2a78d6');
    cNo = hex('#eda100');
    ink = hex('#52514e');
    lw = 1.5;
    nb = size(bands, 1);
    pairs = {[1 4], [2 5]};
    sizes = {'full', 'lite'};
    labels = {'현재 모델', 'no-MRSTFT'};
    colors = {cCur, cNo};

    fig = figure('Visible', 'off', 'Color', hex('#fcfcfb'), 'Units', 'pixels', 'Position', [0 0 1500 1250]);
    tl = tiledlayout(fig, 3, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

    for c = 1:2
        % 스펙트럼 차이
        ax = nexttile(tl, c);
        yline(ax, 0, 'Color', hex('#c3c2b7'), 'LineWidth', 1, 'HandleVisibility', 'off');
        hold(ax, 'on');
        for m = 1:2
            r = R(pairs{c}(m));
            [fc, Sb] = smoothOct(r.fP, r.Pb, 6);
            [~, Sa] = smoothOct(r.fP, r.Pa, 6);
            d = Sa - Sb;
            semilogx(ax, fc, d, 'Color', colors{m}, 'LineWidth', lw, 'DisplayName', labels{m});
            [~, j] = min(abs(fc - 7000));
            yText = d(j) + 4;
            if m == 2
                yText = -8;                        % 곡선과 겹치지 않도록 아래쪽에 고정
            end
            text(ax, fc(j), yText, labels{m}, 'Color', ink, 'FontName', 'Malgun Gothic', ...
                'FontSize', 11, 'HorizontalAlignment', 'right');
        end
        title(ax, sprintf('스펙트럼 차이 (시뮬레이션 - 페달), %s', sizes{c}));
        ylabel(ax, '차이 (dB)');
        ylim(ax, [-10 25]);
        styleAx(ax);
        freqAxis(ax);
        legend(ax, 'Location', 'northwest', 'Box', 'off');

        % 코히어런스 (1/6 옥타브 평균)
        ax = nexttile(tl, 2 + c);
        hold(ax, 'on');
        for m = 1:2
            r = R(pairs{c}(m));
            [fc, Sc] = smoothOct(r.fC(2:end), r.coh(2:end), 6);
            semilogx(ax, fc, 10.^(Sc/10), 'Color', colors{m}, 'LineWidth', lw, 'DisplayName', labels{m});
        end
        title(ax, sprintf('코히어런스 (1/6 옥타브 평균), %s', sizes{c}));
        ylabel(ax, '코히어런스');
        ylim(ax, [0 1.02]);
        styleAx(ax);
        freqAxis(ax);
        legend(ax, 'Location', 'southwest', 'Box', 'off');

        % 대역별 잔차 비율
        ax = nexttile(tl, 4 + c);
        yline(ax, 0, 'Color', hex('#c3c2b7'), 'LineWidth', 1, 'HandleVisibility', 'off');
        hold(ax, 'on');
        for m = 1:2
            r = R(pairs{c}(m));
            plot(ax, 1:nb, 10*log10(r.bandEsr), '-o', 'Color', colors{m}, 'MarkerFaceColor', colors{m}, ...
                'MarkerSize', 8, 'LineWidth', lw, 'DisplayName', labels{m});
        end
        title(ax, sprintf('대역별 잔차 비율 (0 dB = 잔차가 페달만큼 큼), %s', sizes{c}));
        ylabel(ax, '10·log_{10}(ESR) (dB)');
        xlabel(ax, '대역 (Hz)');
        ylim(ax, [-35 15]);
        styleAx(ax);
        ax.XTick = 1:nb;
        ax.XTickLabel = arrayfun(@(lo, hi) sprintf('%s-%s', kfmt(lo), kfmt(hi)), bands(:, 1), bands(:, 2), 'UniformOutput', false);
        ax.XLim = [0.6 nb + 0.4];
        legend(ax, 'Location', 'northwest', 'Box', 'off');
    end

    here = fileparts(mfilename('fullpath'));
    exportgraphics(fig, fullfile(here, 'compare_nomrstft.png'), 'Resolution', 110, 'BackgroundColor', hex('#fcfcfb'));
    close(fig);
end

function s = kfmt(v)
    if v >= 1000
        s = sprintf('%gk', round(v/100)/10);
    else
        s = sprintf('%g', v);
    end
end
