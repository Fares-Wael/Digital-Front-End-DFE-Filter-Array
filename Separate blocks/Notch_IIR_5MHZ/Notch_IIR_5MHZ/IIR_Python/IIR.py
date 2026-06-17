import numpy as np
import matplotlib.pyplot as plt
from scipy.signal import iirnotch, freqz, lfilter
from numpy.fft import fft, fftfreq
import os


# ==============================================================================
# 1) Filter Specifications (5.0 MHz Notch, aliased to 1.0 MHz at Fs=6 MHz)
# ==============================================================================
fs = 6e6        # Sampling rate = 6 MHz
f_target = 5.0e6  # Project spec target
f0 = fs - f_target  # Actual Notch frequency to target = 1.0 MHz
Bw = 50e3       # Bandwidth = 50 kHz
Q = f0 / Bw     # Quality factor (Q = 1e6 / 50e3 = 20.0)

# Fixed-Point Configuration (s16.15)
Q_BITS = 15
Q_SCALE = 2**Q_BITS

# ==============================================================================
# 2) Design IIR Notch Filter (Floating Point)
# ==============================================================================
w0_norm = f0 / (fs/2)
b_float, a_float = iirnotch(w0_norm, Q)

print("=== Filter Coefficients (Float) ===")
print("b =", b_float)
print("a =", a_float)

# =====================================
# 3) Plot Frequency Response
# =====================================
w, h = freqz(b_float, a_float, worN=4096, fs=fs)

plt.figure(figsize=(8, 4))
plt.plot(w, 20*np.log10(np.abs(h)))
# To avoid log(0) use "20*np.log10(np.maximum(np.abs(h), 1e-12)"
plt.title("Notch Filter Frequency Response @ 1 MHz (fs = 6 MHz)")
plt.xlabel("Frequency (Hz)")
plt.ylabel("Magnitude (dB)")
plt.grid(True)
plt.ylim(-80, 5)
plt.tight_layout()
plt.show()


# Coefficients quantized to s16.15 for the Verilog design


def to_q15(arr):
    vals = np.round(np.array(arr) * Q_SCALE).astype(np.int32)
    vals = np.clip(vals, -2**15, 2**15 - 1)
    return vals


b_q15 = to_q15(b_float)
a_q15 = to_q15(a_float)

print("\n=== Quantized Coefficients (s16.15) ===")
print("b_q15 =", b_q15)
print("a_q15 =", a_q15)

# Save Coefficients to file (for documentation)
with open("coefficient_q15.txt", "w") as file:
    file.write(f"a1: {a_q15[1]}\na2: {a_q15[2]}\n")
    file.write(f"b0: {b_q15[0]}\nb1: {b_q15[1]}\nb2: {b_q15[2]}\n")

# ==============================================================================
# 3) Generate Test Signal & Save Input File
# ==============================================================================
duration = 0.0001  # 100 microseconds (600 samples)
t = np.arange(0, duration, 1/fs)

# Composite Signal: Interferer (1.0 MHz) + Desired Signal (0.5 MHz)
F_INTERFERER = 1.0e6
F_PASSTHRU = 0.5e6
AMPLITUDE = 0.45  # Max combined amplitude 0.9 (safe for Q15)

x_float = (AMPLITUDE * np.sin(2 * np.pi * F_INTERFERER * t) +
           AMPLITUDE * np.sin(2 * np.pi * F_PASSTHRU * t))

# Quantize the input signal to s16.15
x_fixed_point = to_q15(x_float)

# Save the fixed-point input to a file for Verilog Testbench
input_filepath = "input_fixed_point.txt"
np.savetxt(input_filepath, x_fixed_point, fmt='%d')
print(
    f"\nGenerated {len(x_fixed_point)} fixed-point input samples and saved to: {input_filepath}")

# ==============================================================================
# 4) Apply Filter (Golden Model) and Save Output
# ==============================================================================
# Use the high-precision floating-point filter on the original float input
y_float = lfilter(b_float, a_float, x_float)
# Quantize the output signal to s16.15
y_fixed_point = to_q15(y_float)

# Save the fixed-point output to a file (This is the Golden Reference)
output_filepath = "python_output_fixed.txt"
np.savetxt(output_filepath, y_fixed_point, fmt='%.8f')
print(
    f"Generated fixed-point reference output and saved to: {output_filepath}")

# Optional: Plot FFT to confirm notch depth
N = len(x_float)
X = np.abs(np.fft.fft(x_float))
Y = np.abs(np.fft.fft(y_float))
freqs = np.fft.fftfreq(N, 1/fs)

plt.figure(figsize=(10, 5))
plt.plot(freqs[:N//2]/1e6, 20*np.log10(X[:N//2]), label="Input (Pre-Filter)")
plt.plot(freqs[:N//2]/1e6, 20*np.log10(Y[:N//2]),
         label="Output (Golden Float)")
plt.title("FFT Comparison: Notch at 1.0 MHz (5.0 MHz Alias)")
plt.xlabel("Frequency (MHz)")
plt.ylabel("Magnitude (dB)")
plt.legend()
plt.grid(True)
plt.show()
