import numpy as np
from scipy.signal import remez, freqz
import matplotlib.pyplot as plt
import os

# ============================================================
# 1. DESIGN REQUIREMENTS & PARAMETERS
# ============================================================

Fs_in = 9e6  # Input sampling rate (9 MHz)
M = 2  # Interpolation factor (Upsampling)
N = 3  # Decimation factor
Fs_up = Fs_in * M  # Intermediate Sample Rate (18 MHz)

Fp = 2.8e6  # Passband Edge frequency (Hz)
Fs = 3.2e6  # Stopband Edge frequency (Hz)

# Convert frequency specs to Normalized Frequency (relative to Nyquist Fs_up/2)
f_norm_p = Fp / (Fs_up / 2)  # Normalized Passband Edge
f_norm_s = Fs / (Fs_up / 2)  # Normalized Stopband Edge

Apass = 0.25  # Passband Ripple (dB)
Astop = 80  # Stopband Attenuation (dB)

# Convert dB specs to linear amplitude tolerances (delta)
# Passband ripple tolerance
delta_p = (10**(Apass/20) - 1) / (10**(Apass/20) + 1)
delta_s = 10**(-Astop/20)  # Stopband attenuation tolerance

# ============================================================
# 2. FILTER DESIGN (REMEZ/PARKS-MCCLELLAN)
# ============================================================

N_taps = 228  # Filter length (Taps), multiple of M=2

# Frequency bands for the Remez algorithm (Normalized)
bands = [0, f_norm_p, f_norm_s, 1.0]

# Desired amplitude in each band (1=Pass, 0=Stop)
desired = [1, 0]

# Weights initialization and adjustment to meet delta ratio
weights = [1/delta_p, 1/delta_s]
weights[0] = delta_s / delta_p  # Adjusted Passband weight
weights[1] = 1  # Stopband weight (Reference)

# Design the FIR filter using Remez algorithm
h = remez(N_taps, bands, desired, weight=weights, fs=2)
# Scale coefficients by M to compensate for gain loss during upsampling
coeff = M * h

print(f"Filter Taps Designed: {len(coeff)}")

# ============================================================
# 3. FIXED-POINT CONVERSION & FILE SAVE
# ============================================================

SCALE = 2**15  # Scaling factor for Q1.15 fixed-point format

# Check and scale down if gain exceeds 1.0 (to prevent Q1.15 overflow)
if np.max(np.abs(coeff)) > 1.0:
    print("WARNING: Filter gain is greater than 1.0. Scaling down.")
    coeff = coeff / np.max(np.abs(coeff))

# Convert to Q1.15 (s16.15) signed 16-bit integer
coeff_int = np.round(coeff * SCALE).astype(np.int16)

# Safety check for 16-bit range overflow
if np.any(coeff_int > 32767) or np.any(coeff_int < -32768):
    raise ValueError("Fixed-point overflow detected. Check scaling.")

# Save integer coefficients to a .dat file (one per line)
coeff_path = "fir_coeffs_228_q15.dec.dat"
np.savetxt(coeff_path, coeff_int, fmt='%d')

print(
    f"\n✅ File '{coeff_path}' generated successfully with {len(coeff_int)} coefficients.")
print(f"First 5 Q1.15 coefficients: {coeff_int[:5]}")
print(f"Equivalent float values: {coeff_int[:5] / SCALE}")

# ============================================================
# 4. FREQUENCY RESPONSE VERIFICATION
# ============================================================

# Calculate the frequency response (H) relative to Fs_up (18 MHz)
w, H = freqz(coeff, worN=2048, fs=Fs_up)

plt.figure(figsize=(10, 5))
# Plot magnitude in dB versus frequency in MHz
plt.plot(w / 1e6, 20 * np.log10(np.maximum(np.abs(H), 1e-12)))
# Add Passband edge marker
plt.axvline(Fp/1e6, color='g', linestyle='--',
            label=f'Passband Edge {Fp/1e6} MHz')
# Add Stopband edge marker
plt.axvline(Fs/1e6, color='r', linestyle='--',
            label=f'Stopband Edge {Fs/1e6} MHz')
plt.title("FIR Filter Frequency Response (Designed for 18 MHz Intermediate Fs)")
plt.xlabel("Frequency (MHz)")
plt.ylabel("Magnitude (dB)")
plt.grid(True, which="both")
plt.ylim(-100, 5)  # Focus on attenuation range
plt.legend()
plt.show()
