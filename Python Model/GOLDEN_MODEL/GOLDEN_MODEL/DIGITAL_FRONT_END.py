import numpy as np
import matplotlib.pyplot as plt
from scipy.signal import iirnotch, lfilter, remez, freqz
import os

# =============================================================================
# 1. إعدادات النظام (System Constants)
# =============================================================================
FS_IN = 9e6             # Input Sampling Rate
FS_MID = 6e6            # After Fractional Decimator
CIC_R = 4               # CIC Decimation Factor
FS_OUT = FS_MID / CIC_R  # Final Output Rate (1.5 MHz)

# Fixed Point Settings
DATA_WIDTH = 16
FRAC_BITS = 15
MAX_VAL = 32767
MIN_VAL = -32768
SCALE = 2**FRAC_BITS

# تحديد مسار الملفات ديناميكياً
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
COEFF_FILE = os.path.join(SCRIPT_DIR, "fir_coeffs_228_q15.dec.dat")

# =============================================================================
# 2. دوال مساعدة (Helper Functions)
# =============================================================================


def to_fixed(float_arr):
    return np.clip(np.round(float_arr * SCALE), MIN_VAL, MAX_VAL).astype(int)


def to_float(fixed_arr):
    return np.array(fixed_arr) / SCALE


def saturate(val):
    if val > MAX_VAL:
        return MAX_VAL
    if val < MIN_VAL:
        return MIN_VAL
    return int(val)

# =============================================================================
# 3. مولد المعاملات (Automatic Coefficient Generator)
# =============================================================================


def generate_coefficients_if_missing():
    if os.path.exists(COEFF_FILE):
        print(f"✅ Coefficient file found: {COEFF_FILE}")
        return

    print("⚠️ Coefficient file NOT found. Generating it now...")

    M = 2
    Fs_up = FS_IN * M
    Fp = 2.8e6
    Fs = 3.2e6
    f_norm_p = Fp / (Fs_up / 2)
    f_norm_s = Fs / (Fs_up / 2)

    Apass = 0.25
    Astop = 80
    delta_p = (10**(Apass/20) - 1) / (10**(Apass/20) + 1)
    delta_s = 10**(-Astop/20)

    N_taps = 228
    bands = [0, f_norm_p, f_norm_s, 1.0]
    desired = [1, 0]
    weights = [delta_s / delta_p, 1]

    h = remez(N_taps, bands, desired, weight=weights, fs=2)
    coeff = M * h

    if np.max(np.abs(coeff)) > 1.0:
        coeff = coeff / np.max(np.abs(coeff))

    coeff_int = np.round(coeff * SCALE).astype(np.int16)

    np.savetxt(COEFF_FILE, coeff_int, fmt='%d')
    print(f"✅ Generated and saved coefficients to: {COEFF_FILE}")

# =============================================================================
# 4. المرحلة الأولى: Fractional Decimator
# =============================================================================


def run_fractional_decimator(input_samples):
    print("⚙️ Running Stage 1: Fractional Decimator (9MHz -> 6MHz)...")

    with open(COEFF_FILE, "r") as f:
        coeffs = [int(line.strip()) for line in f if line.strip()]

    coeffs_even = np.array(coeffs[0::2])
    coeffs_odd = np.array(coeffs[1::2])

    delay_line = np.zeros(len(coeffs), dtype=int)
    output = []
    decim_cnt = 0

    for sample in input_samples:
        delay_line = np.roll(delay_line, 1)
        delay_line[0] = sample

        data_even = delay_line[0::2]
        data_odd = delay_line[1::2]

        phase_0 = np.sum(data_even * coeffs_even)
        phase_1 = np.sum(data_odd * coeffs_odd)

        total = phase_0 + phase_1
        rounded = total + (1 << (FRAC_BITS - 1))
        shifted = rounded >> FRAC_BITS
        result = saturate(shifted)

        if decim_cnt == 2:
            output.append(result)
            decim_cnt = 0
        else:
            decim_cnt += 1

    return np.array(output)

# =============================================================================
# 5. المرحلة الثانية: Notch Filters (IIR) - [تم التعديل هنا]
# =============================================================================


def run_notch_filters(input_samples, fs):
    print("⚙️ Running Stage 2: Dual Notch Filters (Removing 2.4 & 5.0 MHz)...")

    # Specs
    f_notch1 = 2.4e6
    f_notch2 = 1.0e6  # (6.0 - 5.0 Aliased)

    # 🔥 التعديل: وسعنا الـ Bandwidth عشان "يلقط" الإشارة كويس
    bw = 150e3  # 150 kHz بدل 50 kHz (عشان نضمن القص)

    # Design Filter 1 (2.4 MHz)
    Q1 = f_notch1 / bw
    b1, a1 = iirnotch(f_notch1, Q1, fs)

    # Design Filter 2 (1.0 MHz)
    Q2 = f_notch2 / bw
    b2, a2 = iirnotch(f_notch2, Q2, fs)

    # Apply Filters
    data_float = to_float(input_samples)

    # طبق الفلتر الأول
    stage1_out = lfilter(b1, a1, data_float)
    # طبق الفلتر التاني على ناتج الأول
    stage2_out = lfilter(b2, a2, stage1_out)

    return to_fixed(stage2_out)

# =============================================================================
# 6. المرحلة الثالثة: CIC Decimator
# =============================================================================


def run_cic_decimator(input_samples, R, N_stages=3):
    print(f"⚙️ Running Stage 3: CIC Decimator (Down by {R})...")

    integ = input_samples.astype(np.int64)
    for _ in range(N_stages):
        integ = np.cumsum(integ)

    decimated = integ[::R]

    comb = decimated.copy()
    for _ in range(N_stages):
        comb = np.diff(comb, prepend=0)

    gain_bits = int(np.ceil(N_stages * np.log2(R)))
    output = comb >> gain_bits

    return np.clip(output, MIN_VAL, MAX_VAL).astype(int)


# =============================================================================
# 7. التنفيذ الرئيسي والرسم (Main)
# =============================================================================
if __name__ == "__main__":
    generate_coefficients_if_missing()

    # A. Generate Test Signal
    num_samples = 4096 * 2  # زودنا عدد العينات شوية عشان دقة الـ FFT
    t = np.arange(num_samples) / FS_IN

    # Desired Signal (0.5 MHz)
    sig_desired = 0.5 * np.sin(2*np.pi*0.5e6*t)

    # Noise Signals
    sig_noise1 = 0.2 * np.sin(2*np.pi*2.4e6*t)  # Notch 1 Target
    # Notch 2 Target (Aliased to 1.0)
    sig_noise2 = 0.2 * np.sin(2*np.pi*5.0e6*t)
    sig_alias = 0.1 * np.sin(2*np.pi*3.5e6*t)  # Frac Filter Target

    input_signal = to_fixed(sig_desired + sig_noise1 + sig_noise2 + sig_alias)

    # B. Run Chain
    out_frac = run_fractional_decimator(input_signal)
    out_notch = run_notch_filters(out_frac, FS_MID)
    out_cic = run_cic_decimator(out_notch, CIC_R)

    print("\n✅ Simulation Chain Complete!")

    # C. Plotting (Spectrum Analysis)
    def plot_spectrum(sig, fs, title, subplot_idx):
        N = len(sig)
        X = np.abs(np.fft.fft(sig))
        freqs = np.fft.fftfreq(N, 1/fs)

        # Use slicing to avoid log(0)
        half_N = N // 2
        mag_db = 20 * np.log10(X[:half_N] + 1e-12)

        plt.subplot(4, 1, subplot_idx)
        plt.plot(freqs[:half_N]/1e6, mag_db)
        plt.title(title, fontsize=10)
        plt.ylabel("dB")
        plt.grid(True, alpha=0.6)
        plt.xlim(0, fs/2/1e6)
        plt.ylim(0, 160)  # تثبيت المحور الصادي للمقارنة

    plt.figure(figsize=(10, 14))

    plot_spectrum(input_signal, FS_IN,
                  "1. Input (9MHz) [0.5, 2.4, 3.5, 5.0]", 1)
    plt.axvline(2.4, color='r', linestyle='--', alpha=0.3)
    plt.axvline(5.0, color='r', linestyle='--', alpha=0.3)

    plot_spectrum(out_frac, FS_MID,
                  "2. After Frac (6MHz) [3.5 Gone, 5.0->1.0 Alias]", 2)
    plt.axvline(2.4, color='r', linestyle='--', alpha=0.3, label="Target 2.4")
    plt.axvline(1.0, color='g', linestyle='--',
                alpha=0.3, label="Target 1.0 (Alias)")
    plt.legend()

    plot_spectrum(out_notch, FS_MID,
                  "3. After Notch (6MHz) [2.4 & 1.0 Removed!]", 3)

    plot_spectrum(out_cic, FS_OUT,
                  "4. Final Output (1.5MHz) [Clean 0.5MHz]", 4)
    plt.xlabel("Frequency (MHz)")

    plt.tight_layout()
    plt.show()
