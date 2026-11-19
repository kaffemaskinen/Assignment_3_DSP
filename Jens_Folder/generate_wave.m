function [time_vector, signal] = generate_wave(a, f, phi, fs, T_s, type, duty)
% Function call:
%
% >> [time_vector, signal] = generate_sinusoid(a, f, phi, fs, T_s)
%
% INPUT:
% a   : amplitude
% f   : frequency of wave (in Hz)
% phi : phase (in multiples of 2*pi)
% fs  : sampling frequency (in Hz)
% T_s : duration (in seconds)
% type  : 'sin', 'squ', 'tri', 'saw'
% duty  : duty cycle (between 0 and 1) (Only used for square wave)
%
% OUTPUT:
% time_vector : time vector with sampling points
% signal      : the output signal
%
%
% Example:
%
% >> [t, sig] = generate_wave(0.1, 1000, 0, 44100, 1, 'sin')
%
% generates a sinusoid with amplitude 0.1, frequency of 1000 Hz,
% phase zero, sampled at a sampling frequency of 44100 Hz and
% a duration of 1 second.

% Set default duty cycle if not provided
if nargin < 7
    duty = 0.5;
end

% Generate the time vector
time_vector = 0:1/fs:T_s-1/fs;

% Calculate normalized phase
p = mod(f*time_vector + phi, 1);

% Generate waveform depending on input type
switch lower(type)
    case 'sin'
        signal = a * sin(2*pi*p);
        
    case 'squ'
        signal = a * (2*(p < duty) - 1);

    case 'tri'
        signal = a * (1 - 4*abs(p - 0.5));

    case 'saw'
        signal = a * (2*p - 1);

    otherwise
        error('Unknown waveform type');
end

end