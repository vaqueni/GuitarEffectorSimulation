
guitar_files = {
    'DATA/clean tone guitar.wav'
    'DATA/clean tone guitar gain5.wav'
    'DATA/clean tone guitar gain10.wav'
};


files = guitar_files;

figure

for i = 1:length(files)

    [x, fs] = audioread(files{i});

    if size(x,2) > 1
        x = x(:,1);
    end

    N = length(x);
    X = fft(x);

    P2 = abs(X/N);
    P1 = P2(1:N/2+1);
    P1(2:end-1) = 2*P1(2:end-1);

    f = fs*(0:(N/2))/N;

    subplot(length(files),1,i)
    %plot(f,20*log10(P1 + 1e-12))
    %semilogx(f,20*log10(P1 + 1e-12))
    plot(f,P1)
    xlabel('Frequency (Hz)')
    ylabel('Magnitude (dB)')
    title(files{i})
    xlim([0 4.0e+3])
    ylim([0 0.075])
    grid on

end