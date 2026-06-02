
IN = {
    'DATA/sine_440Hz.wav' 
    'DATA/impulse_response.wav'
    'DATA/gaussian_noise.wav'
    'DATA/clean1.wav'
    
    'DATA/sine_440Hz.wav' 
    'DATA/impulse_response.wav'
    'DATA/gaussian_noise.wav'
    'DATA/clean1.wav'
    'DATA/sine_sweep.wav'
    };


OUT = {
    'DATA/f(sine_440Hz).wav' 
    'DATA/f(impulse_response).wav' 
    'DATA/f(gaussian_noise).wav'
    'DATA/janray.wav'
    
    'DATA/DELAY/s_delay.wav'
    'DATA/DELAY/i_delay.wav'
    'DATA/DELAY/g_delay.wav'
    'DATA/DELAY/c_delay.wav'
    'DATA/DELAY/ss_delay.wav'
    };

output_file_name = {
    'OUTPUT/s_estimated_output.wav'
    'OUTPUT/i_estimated_output.wav'
    'OUTPUT/g_estimated_output.wav'
    'OUTPUT/c_estimated_output.wav'

    'OUTPUT/DELAY/s_delay_output.wav'
    'OUTPUT/DELAY/i_delay_output.wav'
    'OUTPUT/DELAY/g_delay_output.wav'
    'OUTPUT/DELAY/c_delay_output.wav'
    'OUTPUT/DELAY/ss_delay_output.wav'
};

%% num 값으로 어떤 데이터를 이용하는 지 적용
num = 7;
%%
% 파일 경로
in  = IN{num};
out = OUT{num};
test_in      = 'DATA/clean2.wav';

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