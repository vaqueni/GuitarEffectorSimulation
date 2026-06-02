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
    [P, f] = pspectrum(x,fs);

    P_dB = 10*log10(P);

    % peak 검출
    [pks, locs] = findpeaks(P_dB, f, ...
        'MinPeakHeight', max(P_dB)-40,...   % 상위 40 dB만
        'MinPeakDistance', 50);              % 너무 가까운 peak 제거

    fprintf('\n%s\n', files{i}(6:end-4));
    fprintf('Peak Frequencies (Hz) | Power (dB)\n');
    fprintf('-----------------------------------\n');
    for k = 1:length(pks)
        fprintf('%10.2f Hz | %8.2f dB\n', locs(k), pks(k));
    end
    % 그래프 생성
    subplot(length(files),1,i);
    plot(f, P_dB)
    xlabel('Frequency (Hz)')
    ylabel('Power (dB)')
    grid on
    title(files{i}(6:end-4))
end

