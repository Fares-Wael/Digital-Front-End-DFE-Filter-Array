# -----------------------------------------------
# Step 0: Import the necessary toolboxes (libraries)
# -----------------------------------------------
import numpy as np
from scipy import signal
import matplotlib.pyplot as plt

print("...Starting 2.4 MHz Notch Filter Design...")

# -----------------------------------------------
# Step 1: Define the Inputs (Specifications)
# -----------------------------------------------
fs = 6e6      # 6.0 MHz (Sampling Frequency)
f0 = 2.4e6    # 2.4 MHz (Target Frequency to remove)
bandwidth = 50e3  # 50 kHz (Desired bandwidth)

# -----------------------------------------------
# Step 2: Design the Filter (Calculate the "Recipe")
# -----------------------------------------------
# Calculate the Quality Factor (Q)
Q = f0 / bandwidth

# Call the design engineer (iirnotch)
# b1 and a1 are the "recipe" we are looking for
b1, a1 = signal.iirnotch(f0, Q, fs)

# -----------------------------------------------
# Step 3: Visual Verification (Plot Filter Response)
# -----------------------------------------------
# Calculate the filter's effect on all frequencies
w, h = signal.freqz(b1, a1, fs=fs)

# Plot the first figure
plt.figure(1)  # This is the first window that will pop up
plt.plot(w / 1e6, 20 * np.log10(abs(h)))
plt.title("Filter Frequency Response - 2.4MHz")
plt.xlabel("Frequency (MHz)")
plt.ylabel("Gain (dB)")
plt.axvline(f0 / 1e6, color='r', linestyle='--', label=f'Target: {f0/1e6} MHz')
plt.grid(True)
plt.legend()
plt.ylim(-100, 5)  # Set Y-limit to see the notch depth clearly

# -----------------------------------------------
# Step 4: Practical Test (Create a Test Signal)
# -----------------------------------------------
# Create a simple test signal for a short duration
t = np.arange(4096) / fs  # 4096 samples

# A useful signal at 1 MHz (in the passband)
sig_good = np.sin(2 * np.pi * 1e6 * t)
# A noise signal at 2.4 MHz (the target)
# sig_bad = np.sin(2 * np.pi * f0 * t)

# Combine the signals (useful + noise)
sig_in = sig_good
# + sig_bad

# -----------------------------------------------
# Step 5: Apply the Filter to the Signal
# -----------------------------------------------
# Use the filter (b1, a1) on the input signal (sig_in)
sig_out = signal.lfilter(b1, a1, sig_in)

# -----------------------------------------------
# Step 6: The Final Verdict (Plot "Before" vs. "After")
# -----------------------------------------------
# Calculate the Frequency Spectrum (FFT) before and after
fft_in = 20 * np.log10(np.abs(np.fft.fft(sig_in)))
fft_out = 20 * np.log10(np.abs(np.fft.fft(sig_out)))
freqs = np.fft.fftfreq(len(t), 1/fs)  # Frequency axis

# Plot the second figure
plt.figure(2)  # This is the second window
plt.plot(freqs / 1e6, fft_in, label="Signal BEFORE Filtering",
         color='blue', alpha=0.7)
plt.plot(freqs / 1e6, fft_out, label="Signal AFTER Filtering",
         color='red', linewidth=2)
plt.title("Signal Spectrum (FFT) - Before vs. After")
plt.xlabel("Frequency (MHz)")
plt.ylabel("Magnitude (dB)")
plt.grid(True)
plt.legend()
plt.ylim(-20, 100)  # Adjust Y-axis to see the peaks clearly

# -----------------------------------------------
# Step 7: Extract the Treasure (Print the Recipe)
# -----------------------------------------------
print("\n...Design Successful...")
print("="*30)
print(f"Coefficients for {f0/1e6} MHz Notch Filter:")
print(f"b = {b1}")
print(f"a = {a1}")
print("="*30)

# -----------------------------------------------
# Final Step: Show the plots
# -----------------------------------------------
print("...Displaying plots...")
plt.show()  # This command will open the plot windows
print("...Script finished.")
