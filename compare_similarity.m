clc; clear; close all;

%% ============================================================
%  Compare one reference wav with selected wav files
%  기준 wav와 직접 지정한 여러 wav 파일의 유사도 비교
%% ============================================================

%% 0) 비교 대상 파일 직접 입력

refFile = 'DATA/delay/c2_delay.wav';

compareFiles = {
    'OUTPUT/delay/c_delay_output.wav'
    'OUTPUT/delay/g_delay_output.wav'
    'OUTPUT/delay/i_delay_output.wav'
    'OUTPUT/delay/s_delay_output.wav'
    'OUTPUT/delay/ss_delay_output.wav'
};

%% 1) 기준 파일 읽기

[x_ref, fs_ref] = audioread(refFile);

% stereo -> mono
if size(x_ref, 2) > 1
    x_ref = mean(x_ref, 2);
end

% column vector
x_ref = x_ref(:);

%% 2) 결과 저장용 table 생성

results = table();

%% 3) 여러 wav 파일 반복 비교

for i = 1:length(compareFiles)

    targetFile = compareFiles{i};

    fprintf('\nComparing with: %s\n', targetFile);

    try
        metrics = compare_wav_similarity(x_ref, fs_ref, targetFile);

        newRow = table( ...
            string(targetFile), ...
            metrics.delay_samples, ...
            metrics.delay_sec, ...
            metrics.correlation, ...
            metrics.ncc, ...
            metrics.mse, ...
            metrics.rmse, ...
            metrics.spectral_cosine, ...
            metrics.log_spectral_mse, ...
            metrics.log_spectral_rmse, ...
            metrics.score, ...
            'VariableNames', { ...
                'FileName', ...
                'DelaySamples', ...
                'DelaySec', ...
                'Correlation', ...
                'NCC', ...
                'MSE', ...
                'RMSE', ...
                'SpectralCosine', ...
                'LogSpectralMSE', ...
                'LogSpectralRMSE', ...
                'SimilarityScore' ...
            } ...
        );

        results = [results; newRow];

    catch ME
        fprintf('Error comparing %s: %s\n', targetFile, ME.message);
    end
end

%% 4) 유사도 점수 기준 정렬

if isempty(results)
    error('비교 결과가 없습니다. 파일 경로나 샘플레이트를 확인하세요.');
end

results = sortrows(results, 'SimilarityScore', 'descend');

%% 5) 결과 출력

fprintf('\n================ Similarity Ranking ================\n');
disp(results);

%% 6) 가장 유사한 파일 출력

fprintf('\n가장 기준 파일과 유사한 파일:\n');
fprintf('File: %s\n', results.FileName(1));
fprintf('Similarity Score: %.4f\n', results.SimilarityScore(1));
fprintf('Correlation: %.4f\n', results.Correlation(1));
fprintf('NCC: %.4f\n', results.NCC(1));
fprintf('Spectral Cosine: %.4f\n', results.SpectralCosine(1));
fprintf('RMSE: %.6f\n', results.RMSE(1));
fprintf('Log Spectral RMSE: %.4f dB\n', results.LogSpectralRMSE(1));

%% 7) CSV 저장

writetable(results, 'OUTPUT/wav_similarity_ranking.csv');
fprintf('\n결과 저장 완료: OUTPUT/wav_similarity_ranking.csv\n');


%% ============================================================
%  Local Function
%  기준 wav와 대상 wav 하나를 비교하는 함수
%
%  주의:
%  MATLAB 스크립트에서 local function은 파일 맨 아래에 있어야 함.
%  이 function 아래에 clc, clear 같은 스크립트 코드를 추가하면 안 됨.
%% ============================================================

function metrics = compare_wav_similarity(x_ref, fs_ref, targetFile)

    %% 1) 대상 wav 읽기

    [y, fs_y] = audioread(targetFile);

    %% 2) 샘플레이트 확인

    if fs_ref ~= fs_y
        error('샘플레이트가 다릅니다. 기준: %d Hz, 대상: %d Hz', fs_ref, fs_y);
    end

    fs = fs_ref;

    %% 3) stereo -> mono

    if size(y, 2) > 1
        y = mean(y, 2);
    end

    %% 4) column vector 변환

    x = x_ref(:);
    y = y(:);

    %% 5) DC 제거

    x = x - mean(x);
    y = y - mean(y);

    %% 6) peak normalization

    x = x / (max(abs(x)) + eps);
    y = y / (max(abs(y)) + eps);

    %% 7) xcorr 기반 시간 정렬

    [c, lags] = xcorr(y, x);
    [~, idx] = max(abs(c));
    delay = lags(idx);

    if delay > 0
        % y가 x보다 뒤에 있는 경우
        y_aligned = y(delay+1:end);
        x_aligned = x(1:length(y_aligned));

    elseif delay < 0
        % x가 y보다 뒤에 있는 경우
        x_aligned = x(-delay+1:end);
        y_aligned = y(1:length(x_aligned));

    else
        x_aligned = x;
        y_aligned = y;
    end

    %% 8) 길이 맞추기

    N = min(length(x_aligned), length(y_aligned));
    x_aligned = x_aligned(1:N);
    y_aligned = y_aligned(1:N);

    %% 9) Time-domain 유사도 계산

    mse_val = mean((x_aligned - y_aligned).^2);
    rmse_val = sqrt(mse_val);

    corr_matrix = corrcoef(x_aligned, y_aligned);

    if numel(corr_matrix) >= 4
        corr_val = corr_matrix(1, 2);
    else
        corr_val = 0;
    end

    ncc_val = sum(x_aligned .* y_aligned) / ...
        (sqrt(sum(x_aligned.^2)) * sqrt(sum(y_aligned.^2)) + eps);

    %% 10) Frequency-domain 유사도 계산

    X = abs(fft(x_aligned));
    Y = abs(fft(y_aligned));

    halfN = floor(N / 2);

    X_half = X(1:halfN);
    Y_half = Y(1:halfN);

    spectral_cosine = dot(X_half, Y_half) / ...
        ((norm(X_half) * norm(Y_half)) + eps);

    X_db = 20 * log10(X_half + 1e-9);
    Y_db = 20 * log10(Y_half + 1e-9);

    log_spectral_mse = mean((X_db - Y_db).^2);
    log_spectral_rmse = sqrt(log_spectral_mse);

    %% 11) 통합 유사도 점수 계산
    %
    % 높을수록 유사함.
    %
    % Correlation, SpectralCosine:
    %   높을수록 좋음
    %
    % RMSE, LogSpectralRMSE:
    %   낮을수록 좋으므로 1 / (1 + error) 형태로 변환

    corr_score = max(corr_val, 0);
    spectral_score = spectral_cosine;

    rmse_score = 1 / (1 + rmse_val);
    log_spec_score = 1 / (1 + log_spectral_rmse);

    score = ...
        0.35 * corr_score + ...
        0.35 * spectral_score + ...
        0.15 * rmse_score + ...
        0.15 * log_spec_score;

    %% 12) 결과 저장

    metrics.delay_samples = delay;
    metrics.delay_sec = delay / fs;
    metrics.correlation = corr_val;
    metrics.ncc = ncc_val;
    metrics.mse = mse_val;
    metrics.rmse = rmse_val;
    metrics.spectral_cosine = spectral_cosine;
    metrics.log_spectral_mse = log_spectral_mse;
    metrics.log_spectral_rmse = log_spectral_rmse;
    metrics.score = score;

end