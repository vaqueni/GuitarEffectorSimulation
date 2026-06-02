function y_out = apply_transfer_function(x_in, H)
% apply_transfer_function
% x_in : 새 입력 신호
% H    : estimate_transfer_function에서 추정한 전달함수

    if size(x_in,2) > 1
        x_in = mean(x_in,2);
    end
    x_in = x_in(:);

    N_in = length(x_in);
    N_H  = length(H);

    % H 길이에 맞춰 보간
    old_idx = linspace(0, 1, N_H);
    new_idx = linspace(0, 1, N_in);

    H_real = interp1(old_idx, real(H), new_idx, 'linear', 0);
    H_imag = interp1(old_idx, imag(H), new_idx, 'linear', 0);
    H_new = H_real(:) + 1j * H_imag(:);

    % 적용
    X_in = fft(x_in, N_in);
    Y_out = X_in .* H_new;
    y_out = real(ifft(Y_out));

    % normalize
    peak = max(abs(y_out));
    if peak > 0
        y_out = 0.95 * y_out / peak;
    end
end