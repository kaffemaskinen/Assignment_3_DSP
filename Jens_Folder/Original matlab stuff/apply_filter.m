function filtered_signal = apply_filter(signal, fs, filterType, cutoff, order)
% Function call:
%
% >> filtered_signal = apply_filter(signal, fs, filterType, cutoff, order)
%
% INPUT:
% signal     : Input signal
%
% fs         : Sampling frequency (in Hz) (Should be the same as the
%              sampling frequency used when generating the wave)
%
% filterType : Type of filter:
%              'LP' : Low-pass  (Allows low frequencies through)
%              'HP' : High-pass (Allows high frequencies through)
%              'BP' : Band-pass (Allows a specific frequency range through)
%              'BS' : Band-stop (Removes a specific frequency range)
%              'AP' : All-pass  (Allows all frequencies through, order does
%                                not matter since i only have 1st order
%                                implemented)
%
% cutoff     : Cutoff frequency/frequencies (in Hz)
%              LP and HP: One cutoff frequency
%              BP and BS: Two cutoff frequencies [lower upper]
%
% order      : Filter order (Decides how aggressive the filter is outside
%                           the passband)
%
% OUTPUT:
% filtered_signal : The filtered input signal
%
% This function generates a digital Butterworth filter of the selected
% type and order, and applies it to the input signal.
%
% Example:
%
% >> filtered_signal = apply_filter(signal, 44100, 'LP', 2000, 4)
%
% applies a 4th order low-pass filter to the input signal, with a sampling
% frequency of 44100 Hz and a cutoff frequency of 2000 Hz.


% Check if cutoff frequency is above or equal to Nyquist frequency
if any(cutoff >= fs/2)
    warning('Cutoff frequency is above or equal to Nyquist frequency. Results may be unreliable.');
end

% Normalize cutoff frequency
Wn = cutoff / (fs/2);

% Design filter
switch upper(filterType)

    case 'LP'
        [b, a] = butter(order, Wn, 'low');

    case 'HP'
        [b, a] = butter(order, Wn, 'high');

    case 'BP'
        [b, a] = butter(order, Wn, 'bandpass');

    case 'BS'
        [b, a] = butter(order, Wn, 'stop');

    case 'AP'
        % First-order all-pass filter
        alpha = (1 - tan(pi*cutoff/fs)) / (1 + tan(pi*cutoff/fs));

        b = [alpha 1];
        a = [1 alpha];

    otherwise
        error('Unknown filter type. Use LP, HP, BP, BS or AP');
end

% Apply filter
filtered_signal = filter(b, a, signal);

end
