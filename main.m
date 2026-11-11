
IN = {
    'DATA/source/sine_440Hz.wav' 
    'DATA/source/impulse_response.wav'
    'DATA/source/gaussian_noise.wav'
    'DATA/source/clean1.wav'
    
    'DATA/source/sine_440Hz.wav' 
    'DATA/source/impulse_response.wav'
    'DATA/source/gaussian_noise.wav'
    'DATA/source/clean1.wav'
    'DATA/source/sine_sweep.wav'
    };


OUT = {
    'DATA/janray/f(sine_440Hz).wav' 
    'DATA/janray/f(impulse_response).wav' 
    'DATA/janray/f(gaussian_noise).wav'
    'DATA/janray/janray.wav'
    
    'DATA/delay/s_delay.wav'
    'DATA/delay/i_delay.wav'
    'DATA/delay/g_delay.wav'
    'DATA/delay/c_delay.wav'
    'DATA/delay/ss_delay.wav'
    };

output_file_name = {
    'OUTPUT/janray/s_estimated_output.wav'
    'OUTPUT/janray/i_estimated_output.wav'
    'OUTPUT/janray/g_estimated_output.wav'
    'OUTPUT/janray/c_estimated_output.wav'

    'OUTPUT/delay/s_delay_output.wav'
    'OUTPUT/delay/i_delay_output.wav'
    'OUTPUT/delay/g_delay_output.wav'
    'OUTPUT/delay/c_delay_output.wav'
    'OUTPUT/delay/ss_delay_output.wav'
};

%% num 값으로 어떤 데이터를 이용하는 지 적용
num = 7;
%%
% 파일 경로
in  = IN{num};
out = OUT{num};
test_in      = 'DATA/source/clean2.wav';

% 읽기
[x, fs] = audioread(in);
[y, fs2] = audioread(out);
[x_test, fs3] = audioread(test_in);

if fs ~= fs2 || fs ~= fs3
    error('샘플링 레이트가 다릅니다.');
end

% 전달함수 추정
[H, f] = estimate_transfer_function(x, y, fs, true);

% 새 입력에 적용
y_est = apply_transfer_function(x_test, H);

% 저장
audiowrite(output_file_name{num}, y_est, fs);

% 확인용 파형
figure;
subplot(2,1,1);
plot(x_test);
title('Input Test Signal');

subplot(2,1,2);
plot(y_est);
title('Estimated Output Signal');