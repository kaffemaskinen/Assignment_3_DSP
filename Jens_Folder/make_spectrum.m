function [Y, freq] = make_spectrum(signal, fs)
% MAKE_SPECTRUM Calculate the complex spectrum of a signal.
%
%   [Y, freq] = make_spectrum(signal, fs)
%
%   Inputs:
%       signal - input time-domain signal
%       fs     - sampling frequency in Hz
%
%   Outputs:
%       Y      - complex spectrum of the signal
%       freq   - corresponding frequency vector in Hz

% compute spectrum (note: it will be complex-valued).
Y = fft(signal);
N = length(Y);

% The FFT needs to be scaled in order to give a physically plausible scaling.
Y = Y/N;

% NOTE: If you do an IFFT, this scaling must NOT be done.
% We'll get to this in the lecture. If you are only interested
% in the positive frequencies, you need to scale by <length(Y)/2>.
% frequency vector
delta_f = fs/N;
freq = 0:delta_f:(N-1)*delta_f;

% NOTE: The first element that comes out of the FFT is the DC offset
% (i.e., frequency 0). Each subsequent
% bin is spaced by the frequency resolution <delta_f> which you can
% calculate from the properties of the inut signal. Remember the highest
% frequency you can get in a digitized signal....
% ...
% convert into column vector (if required)
Y = Y(:);
freq = freq(:);
% eof
end