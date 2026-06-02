guitar_files = {
    'DATA/clean tone guitar.wav'
    'DATA/clean tone guitar gain5.wav'
    'DATA/clean tone guitar gain10.wav'
    'DATA/'
};



files = guitar_files;

figure

for i = 1:length(files)
    
    [x, fs] = audioread(files{i});
    [P, f] = pspectrum(x,fs);

    P_dB = 10*log10(P);

    % 그래프 생성
    subplot(length(files),1,i);
    plot(f, P_dB)
    xlabel('Frequency (Hz)')
    ylabel('Power (dB)')
    grid on
    title(files{i}(6:end-4))
    ylim([-150,0])
end

