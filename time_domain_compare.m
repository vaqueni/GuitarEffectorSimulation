files = {
    'DATA/delay/g_delay.wav'
    'DATA/source/gaussian_noise.wav'

};

figure

for i = 1:length(files)
    
    [x, fs] = audioread(files{i});
    
    if size(x,2) > 1
        x = x(:,1);
    end

    t = (0:length(x)-1)/fs;

    subplot(length(files),1,i)
    plot(t, x)
    xlabel('Time (s)')
    ylabel('Amplitude')
    xlim([0 8])
    ylim([-1.1 1.1])
    title(files{i}(6:end-4))
    grid on
end