function [H, f] = estimate_transfer_function(x, y, fs, doPlot)

    if nargin < 4
        doPlot = true;
    end

    if size(x,2) > 1, x = mean(x,2); end
    if size(y,2) > 1, y = mean(y,2); end
    x = x(:);
    y = y(:);

    N = min(length(x), length(y));
    x = x(1:N);
    y = y(1:N);

    [c, lags] = xcorr(y, x);
    [~, idx] = max(abs(c));
    delay = lags(idx);

    if delay > 0
        y = y(delay+1:end);
        x = x(1:end-delay);
    elseif delay < 0
        x = x(-delay+1:end);
        y = y(1:end+delay);
    end

    N = min(length(x), length(y));
    x = x(1:N);
    y = y(1:N);

    w = hann(N);
    X = fft(x .* w);
    Y = fft(y .* w);

    lambda = 1e-6 * max(abs(X).^2);
    H = (Y .* conj(X)) ./ (abs(X).^2 + lambda);

    % magnitude만 smoothing
    Hmag = smoothdata(abs(H), 'movmean', 31);
    Hpha = angle(H);
    H = Hmag .* exp(1j * Hpha);

    % gain 제한
    maxGain = 8;
    H = min(abs(H), maxGain) .* exp(1j * angle(H));

    f = (0:N-1)' * (fs/N);

    if doPlot
        halfIdx = 1:floor(N/2);

        figure;
        subplot(2,1,1);
        semilogx(f(halfIdx), 20*log10(abs(H(halfIdx)) + 1e-12), 'LineWidth', 1.2);
        xlabel('Frequency (Hz)');
        ylabel('Magnitude (dB)');
        title('Estimated Transfer Function Magnitude');
        xlim([20 fs/2]);
        grid on;

        subplot(2,1,2);
        semilogx(f(halfIdx), unwrap(angle(H(halfIdx))), 'LineWidth', 1.2);
        xlabel('Frequency (Hz)');
        ylabel('Phase (rad)');
        title('Estimated Transfer Function Phase');
        xlim([20 fs/2]);
        grid on;
    end
end