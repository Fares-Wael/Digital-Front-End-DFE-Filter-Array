import numpy as np
import matplotlib.pyplot as plt
import os

# =============================================================================
# 1. Simulation Parameters (Must Match Verilog)
# =============================================================================
DATA_WIDTH = 16
COEFF_WIDTH = 16
FRAC_BITS = 15

# Derived Parameters
MAX_VAL = 2**(DATA_WIDTH-1) - 1  # 32767
MIN_VAL = -2**(DATA_WIDTH-1)      # -32768
ROUND_BIAS = (1 << (FRAC_BITS - 1))

# File Paths
script_dir = os.path.dirname(os.path.abspath(__file__))
INPUT_FILE = os.path.join(script_dir, "input_data.dat")
COEFF_FILE = os.path.join(script_dir, "fir_coeffs_228_q15.dec.dat")
VERILOG_OUT_FILE = os.path.join(script_dir, "verilog_output.dat")

# =============================================================================
# 2. Helper Functions
# =============================================================================


def to_signed(val, bits):
    """Convert Unsigned Hex/Int to Signed Integer"""
    val = val & ((1 << bits) - 1)  # Mask
    if val >= (1 << (bits - 1)):
        return val - (1 << bits)
    return val


def saturate(val):
    """Saturation Logic to 16-bit Signed"""
    if val > MAX_VAL:
        return MAX_VAL
    if val < MIN_VAL:
        return MIN_VAL
    return int(val)


# =============================================================================
# 3. Load Data
# =============================================================================
print("🔄 Reading files...")

# A. Load Input Data
input_samples = []
if os.path.exists(INPUT_FILE):
    with open(INPUT_FILE, "r") as f:
        for line in f:
            if line.strip():
                # Read Hex (e.g., "F0A2") -> Signed Int
                val = int(line.strip(), 16)
                input_samples.append(to_signed(val, 16))
    print(f"   ✅ Loaded {len(input_samples)} samples from input_data.dat")
else:
    print(f"   ❌ Error: {INPUT_FILE} not found.")
    exit()

# B. Load Coefficients
coeffs = []
if os.path.exists(COEFF_FILE):
    with open(COEFF_FILE, "r") as f:
        coeffs = [int(line.strip()) for line in f if line.strip()]
    print(f"   ✅ Loaded {len(coeffs)} coefficients.")
else:
    print(f"   ❌ Error: {COEFF_FILE} not found.")
    exit()

# Separate Coefficients into Even and Odd Phases (Polyphase)
# Verilog Logic: Phase 0 uses Even coeffs, Phase 1 uses Odd coeffs
coeffs_even = np.array(coeffs[0::2])  # Indices 0, 2, 4...
coeffs_odd = np.array(coeffs[1::2])  # Indices 1, 3, 5...
N_TAPS_PHASE = len(coeffs_even)  # Should be 114

# =============================================================================
# 4. Run Python Golden Model (Emulating Verilog Logic Exactly)
# =============================================================================
print("🔄 Running Python emulation of Verilog logic...")

# Buffer to simulate the Shift Register (Delay Line)
# Initialize with zeros (size 228)
delay_line = np.zeros(len(coeffs), dtype=int)
python_output = []

# Decimation Counter (0, 1, 2)
decim_cnt = 0

for sample in input_samples:
    # 1. Shift & Load (Shift Right, load at 0) -> Matches Verilog `delay_line_shift_reg` logic
    # Note: In Python arrays, index 0 is usually left.
    # If Verilog delay_line[0] is newest:
    # We shift existing data to higher indices:
    delay_line = np.roll(delay_line, 1)  # Shift right
    delay_line[0] = sample  # Load new sample at index 0

    # 2. Snapshot & Calculate (Parallel MAC)
    # Verilog: chunk_products[j] = delay_snapshot[abs_index] * coeff
    # The indexing we fixed: Even Coeffs multiply Even indices of delay line (0, 2, 4...)
    # Odd Coeffs multiply Odd indices of delay line (1, 3, 5...)

    # Extract data for phases
    data_even = delay_line[0::2]  # Indices 0, 2, 4... (114 samples)
    data_odd = delay_line[1::2]  # Indices 1, 3, 5... (114 samples)

    # Perform MACs
    # Note: In standard convolution, we reverse coeffs, but in this direct FIR structure:
    # product = data[i] * coeff[i]

    # Phase 0 Sum (Even * Even)
    phase_0_sum = np.sum(data_even * coeffs_even)

    # Phase 1 Sum (Odd * Odd) - Note: delay_snapshot[abs_index] where abs_index is odd
    phase_1_sum = np.sum(data_odd * coeffs_odd)

    # 3. Combine
    total_sum = phase_0_sum + phase_1_sum

    # 4. Rounding & Truncation
    # Verilog: rounded_sum = total_final_sum + (1 << (FRAC_BITS - 1));
    rounded_sum = total_sum + ROUND_BIAS
    shifted_sum = rounded_sum >> FRAC_BITS

    # 5. Saturation
    sat_result = saturate(shifted_sum)

    # 6. Decimation Logic
    # Verilog: output valid when decim_cnt == 2
    if decim_cnt == 2:
        python_output.append(sat_result)
        decim_cnt = 0
    else:
        decim_cnt += 1

print(f"   ✅ Generated {len(python_output)} output samples (Decimated by 3).")

# =============================================================================
# 5. Compare with Verilog Output
# =============================================================================
verilog_out = []
if os.path.exists(VERILOG_OUT_FILE):
    with open(VERILOG_OUT_FILE, "r") as f:
        verilog_out = [int(line.strip()) for line in f if line.strip()]
    print(f"   ✅ Loaded {len(verilog_out)} samples from verilog_output.dat")
else:
    print(f"   ⚠️ Warning: verilog_output.dat not found.")

if verilog_out:
    min_len = min(len(python_output), len(verilog_out))

    # Align signals (Find best offset due to latency)
    best_offset = 0
    min_error = float('inf')

    # Search for alignment in first 50 samples
    for offset in range(50):
        if offset + min_len > len(python_output):
            break

        # Slicing
        py_slice = python_output[offset: offset + min_len]
        v_slice = verilog_out[:len(py_slice)]

        # Calculate diff sum
        diff = np.sum(np.abs(np.array(py_slice) - np.array(v_slice)))

        if diff < min_error:
            min_error = diff
            best_offset = offset

    print(f"   ℹ️  Best alignment offset: {best_offset} samples")

    # Final Comparison
    py_final = python_output[best_offset: best_offset + min_len]
    v_final = verilog_out[:len(py_final)]

    error_signal = np.array(py_final) - np.array(v_final)
    mse = np.mean(error_signal**2)
    max_err = np.max(np.abs(error_signal))

    print("\n📊 RESULTS:")
    print(f"   - MSE: {mse:.4f}")
    print(f"   - Max Error: {max_err}")

    if mse < 5.0:  # Allowing small rounding differences
        print("   🌟 PASS: Python and Verilog match!")
    else:
        print("   ❌ FAIL: Mismatch detected.")

    # Plot
    plt.figure(figsize=(12, 8))
    plt.subplot(2, 1, 1)
    plt.plot(py_final[:200], label="Python (Emulation)",
             linewidth=2, alpha=0.7)
    plt.plot(v_final[:200], label="Verilog", linestyle="--", color="red")
    plt.title(f"Verification Match (MSE: {mse:.2f})")
    plt.legend()
    plt.grid(True)

    plt.subplot(2, 1, 2)
    plt.plot(error_signal[:200], color="orange", label="Error")
    plt.title("Error Difference")
    plt.legend()
    plt.grid(True)

    plt.tight_layout()
    plt.show()

else:
    # Plot only Python if Verilog not present
    plt.plot(python_output[:200])
    plt.title("Python Emulation Output (3 MHz)")
    plt.grid(True)
    plt.show()
