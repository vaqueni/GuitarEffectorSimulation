sine_files = {
    'DATA/sine wave.wav'
    'DATA/sine wave gain5.wav'
    'DATA/sine wave gain10.wav'
    'DATA/f(sine_440Hz).wav'
};



files = sine_files;

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
    plot(f,20*log10(P1 + 1e-12))
    %semilogx(f,20*log10(P1 + 1e-12))
    %plot(f,P1)
    xlabel('Frequency (Hz)')
    ylabel('Magnitude (dB)')
    title(files{i})
   % xlim([0 4.0e+3])
    %ylim([0 1.5])
    grid on

end