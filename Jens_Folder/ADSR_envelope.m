function envelope = ADSR_envelope(fs, T_s, attack, decay, sustain, release, curvetype)
% Function call:
%
% >> envelope = generate_ADSR(fs, T_s, attack, decay, sustain, release)
%
% INPUT:
% fs      : Sampling frequency (in Hz) (Should be the same as the wave it
%                                       should be multiplied with)
%
% T_s     : Total duration of the sound (in seconds) (Same requirement as fs)
% attack  : Attack duration (in seconds)
% decay   : Decay duration (in seconds)
% sustain : Sustain amplitude (between 0 and 1) (sustain time not needed
%                                               because of total time)
% release : Release duration (in seconds)
%
% OUTPUT:
% envelope : ADSR amplitude envelope
%
% This function generates a linear ADSR envelope with four stages, which
% can be used to multiply with whatever wave we have
%
% Example:
%
% >> envelope = ADSR_envelope(1000, 1, 0.2, 0.3, 0.6, 0.5)
%
% generates an ADSR envelope with a frequency of 1000 Hz, a duration of
% 1 second, where the attack is 0.2 seconds long, decay is 0.3 seconds
% long, the sustain amplitude is at 0.6, and the release is 0.5 seconds
% long.

% If no curvetype input, assume linear
if nargin < 7
    curvetype = 'lin';
end

% Check for any problems with the inputs
if attack < 0 || decay < 0 || release < 0
    error('Attack, decay and release must be non-negative');
end

if sustain < 0 || sustain > 1
    error('Sustain must be between 0 and 1');
end

if attack + decay + release > T_s
    error('ADSR durations exceed total duration T_s');
end

% Get total samples
time_vector = 0:1/fs:T_s-1/fs;
N = length(time_vector);

% Find how many samples per stage in the ADSR (Rounded since we need whole
% numbers)
nAttack  = round(attack * fs); % Attack samples
nDecay   = round(decay * fs); % Decay samples
nRelease = round(release * fs); % Release samples

% We calculate sustain by taking total samples and subtracting the other
% stages samples to make sure we have the right amount of samples (since we
% round them). Like this the sustain part takes care of any rounding errors
nSustain = N - nAttack - nDecay - nRelease; % Sustain samples

% To make sure we dont f.ex. have 2 samples that are 1 when going from
% attack to decay, we use sample indices and linspace
attack_idx = 1:nAttack;
decay_idx = nAttack+1 : nAttack+nDecay;
sustain_idx = nAttack+nDecay+1 : nAttack+nDecay+nSustain;
release_idx = nAttack+nDecay+nSustain+1 : N;

% Prepare empty envelope for the values
envelope = zeros(1, N);

% Change "envelope" depending on of 'lin' or 'exp' has been input
switch lower(curvetype)

    case 'lin'

        envelope(attack_idx) = linspace(0, 1, nAttack);         % A
        envelope(decay_idx) = linspace(1, sustain, nDecay);     % D
        envelope(sustain_idx) = sustain;                        % S
        envelope(release_idx) = linspace(sustain, 0, nRelease); % R


    case 'exp'
        % For exponential we use a default curve, otherwise there would be
        % way too many inputs for the function

        k = 5;

        % A
        x = linspace(0, 1, nAttack);
        envelope(attack_idx) = (1-exp(-k*x))/(1-exp(-k));

        % D
        x = linspace(0, 1, nDecay);
        curve = (1-exp(-k*x))/(1-exp(-k));
        envelope(decay_idx) = 1-(1-sustain)*curve;

        % S
        envelope(sustain_idx) = sustain;

        % R
        x = linspace(0, 1, nRelease);
        curve = (1-exp(-k*x))/(1-exp(-k));
        envelope(release_idx) = sustain*(1-curve);


    otherwise
        error('Unknown curve type');
end

end