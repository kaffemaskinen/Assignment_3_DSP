import numpy as np
from scipy.signal import butter, lfilter

def generate_wave(a, f, phi, fs, T_s, type, duty=0.5):
    """
    Generate a sinusoidal, square, triangular, or sawtooth waveform.

    Parameters
    ----------
    a : float
        Amplitude of the wave.

    f : float
        Frequency of the wave (Hz).

    phi : float
        Phase in multiples of 2*pi.

    fs : float
        Sampling frequency (Hz).

    T_s : float
        Duration of the signal (seconds).

    type : str
        Waveform type: 'sin', 'squ', 'tri', or 'saw'.
        
    duty : float, optional
        Duty cycle between 0 and 1 (square wave only).
        Default is 0.5.

    Returns
    -------
    time_vector : numpy.ndarray
        Time vector containing the sampling points.

    signal : numpy.ndarray
        Generated waveform.
    """

    # Generate the time vector
    time_vector = np.arange(0, T_s, 1/fs)

    # Calculate normalized phase
    p = np.mod(f * time_vector + phi, 1)

    # Generate waveform depending on input type
    waveform_type = type.lower()

    if waveform_type == 'sin':
        signal = a * np.sin(2 * np.pi * p)

    elif waveform_type == 'squ':
        signal = a * (2 * (p < duty) - 1)

    elif waveform_type == 'tri':
        signal = a * (1 - 4 * np.abs(p - 0.5))

    elif waveform_type == 'saw':
        signal = a * (2 * p - 1)

    else:
        raise ValueError("Unknown waveform type. Use 'sin', 'squ', 'tri', or 'saw'.")

    return time_vector, signal










def ADSR_envelope(fs, T_s, attack, decay, sustain, release, curvetype='lin'):
    """
    Generate an ADSR amplitude envelope.

    Parameters
    ----------
    fs : float
        Sampling frequency (Hz).

    T_s : float
        Total duration (seconds).

    attack : float
        Attack duration (seconds).

    decay : float
        Decay duration (seconds).

    sustain : float
        Sustain amplitude (between 0 and 1).

    release : float
        Release duration (seconds).

    curvetype : str, optional
        Envelope curve type: 'lin' or 'exp'.
        Default is 'lin'.

    Returns
    -------
    envelope : numpy.ndarray
        ADSR amplitude envelope.
    """

    # Check inputs
    if attack < 0 or decay < 0 or release < 0:
        raise ValueError("Attack, decay and release must be non-negative")

    if sustain < 0 or sustain > 1:
        raise ValueError("Sustain must be between 0 and 1")

    if attack + decay + release > T_s:
        raise ValueError("ADSR durations exceed total duration T_s")

    # Get total number of samples
    time_vector = np.arange(0, T_s, 1/fs)
    N = len(time_vector)

    # Calculate number of samples per ADSR stage
    nAttack = round(attack * fs)
    nDecay = round(decay * fs)
    nRelease = round(release * fs)

    # Sustain takes the remaining samples
    nSustain = N - nAttack - nDecay - nRelease

    # Prepare empty envelope
    envelope = np.zeros(N)

    # Define sample indices
    attack_idx = slice(0, nAttack)
    decay_idx = slice(nAttack, nAttack + nDecay)

    sustain_idx = slice(
        nAttack + nDecay,
        nAttack + nDecay + nSustain
    )

    release_idx = slice(
        nAttack + nDecay + nSustain,
        N
    )

    # Generate envelope depending on curve type
    curvetype = curvetype.lower()

    if curvetype == 'lin':

        # Attack
        envelope[attack_idx] = np.linspace(0, 1, nAttack)

        # Decay
        envelope[decay_idx] = np.linspace(1, sustain, nDecay)

        # Sustain
        envelope[sustain_idx] = sustain

        # Release
        envelope[release_idx] = np.linspace(sustain, 0, nRelease)

    elif curvetype == 'exp':

        # Default exponential curve constant
        k = 5

        # Attack
        x = np.linspace(0, 1, nAttack)
        envelope[attack_idx] = (1 - np.exp(-k*x)) / (1 - np.exp(-k))

        # Decay
        x = np.linspace(0, 1, nDecay)
        curve = (1 - np.exp(-k*x)) / (1 - np.exp(-k))
        envelope[decay_idx] = 1 - (1 - sustain) * curve

        # Sustain
        envelope[sustain_idx] = sustain

        # Release
        x = np.linspace(0, 1, nRelease)
        curve = (1 - np.exp(-k*x)) / (1 - np.exp(-k))
        envelope[release_idx] = sustain * (1 - curve)

    else:
        raise ValueError("Unknown curve type. Use 'lin' or 'exp'.")

    return envelope










def apply_filter(signal, fs, filterType, cutoff, order):
    """
    Apply a Butterworth filter or first-order all-pass filter.

    Parameters
    ----------
    signal : numpy.ndarray
        Input signal.

    fs : float
        Sampling frequency (Hz).

    filterType : str
        Filter type: 'LP', 'HP', 'BP', 'BS', or 'AP'.

    cutoff : float or list
        Cutoff frequency/frequencies (Hz).
        LP and HP: Single frequency.
        BP and BS: Two frequencies [lower, upper].
        AP: Single frequency.
        
    order : int
        Filter order (not used for AP).

    Returns
    -------
    filtered_signal : numpy.ndarray
        Filtered input signal.
    """

    # Check cutoff frequency against Nyquist frequency
    if np.any(np.asarray(cutoff) >= fs/2):
        import warnings
        warnings.warn(
            "Cutoff frequency is above or equal to Nyquist frequency. "
            "Results may be unreliable."
        )

    # Normalize cutoff frequency
    Wn = np.asarray(cutoff) / (fs/2)

    # Design filter
    filterType = filterType.upper()

    if filterType == 'LP':
        b, a = butter(order, Wn, btype='low')

    elif filterType == 'HP':
        b, a = butter(order, Wn, btype='high')

    elif filterType == 'BP':
        b, a = butter(order, Wn, btype='bandpass')

    elif filterType == 'BS':
        b, a = butter(order, Wn, btype='bandstop')

    elif filterType == 'AP':
        # First-order all-pass filter
        alpha = (1 - np.tan(np.pi * cutoff / fs)) / \
                (1 + np.tan(np.pi * cutoff / fs))

        b = [alpha, 1]
        a = [1, alpha]

    else:
        raise ValueError(
            "Unknown filter type. Use LP, HP, BP, BS or AP."
        )

    # Apply filter
    filtered_signal = lfilter(b, a, signal)

    return filtered_signal










def make_spectrum(signal, fs):
    """
    Calculate the complex spectrum of a signal.

    Parameters
    ----------
    signal : numpy.ndarray
        Input time-domain signal.

    fs : float
        Sampling frequency (Hz).

    Returns
    -------
    Y : numpy.ndarray
        Complex spectrum of the signal.
        
    freq : numpy.ndarray
        Corresponding frequency vector (Hz).
    """

    # Compute spectrum (complex-valued)
    Y = np.fft.fft(signal)

    # Get number of samples
    N = len(Y)

    # Scale spectrum
    Y = Y / N

    # Calculate frequency resolution
    delta_f = fs / N

    # Generate frequency vector
    freq = np.arange(N) * delta_f

    # Return as column vectors (similar to MATLAB)
    Y = Y.reshape(-1, 1)
    freq = freq.reshape(-1, 1)

    return Y, freq