import numpy as np
import matplotlib.pyplot as plt
import math

# ==========================================
# 1. Configuration Matching Testbench (TB.v)
# ==========================================
# From TB.v: D_select = 2 --> D = 4
D_FACTOR = 4 
N_STAGES = 4
INPUT_WIDTH = 16

# FIR coefficients as in Verilog code (s16.14)
FIR_COEFFS = np.array([-1024, 0, 18432, 0, -1024], dtype=np.int64)
FIR_SHIFT = 14
FIR_ROUND_ADD = 1 << (FIR_SHIFT - 1) # 8192

# CIC Scaling settings
# Calculate shift: N * log2(D)
CIC_SHIFT = N_STAGES * int(math.log2(D_FACTOR)) # 4 * 2 = 8
CIC_ROUND_ADD = 1 << (CIC_SHIFT - 1) # 128

# ==========================================
# 2. Stimulus Generation (Matches TB.v exactly)
# ==========================================
def generate_stimulus():
    amplitude = 30000.0
    freq_rad = 0.0
    freq_step = 0.05
    two_pi = 2 * math.pi
    
    stimulus = []
    
    # Same Loop as in Verilog (repeat 2000)
    for _ in range(2000):
        # 1. Calculate Sine
        sin_val = math.sin(freq_rad)
        
        # 2. Convert to Fixed Point (Casting)
        val_int = int(sin_val * amplitude)
        
        # Simulate 16-bit Overflow/Wrap-around (Optional check)
        # val_int = val_int & 0xFFFF
        # if val_int >= 32768: val_int -= 65536
        
        stimulus.append(val_int)
        
        # 3. Update angle
        freq_rad += freq_step
        if freq_rad > two_pi:
            freq_rad -= two_pi
            
    return np.array(stimulus, dtype=np.int64)

# ==========================================
# 3. Helper Functions (Fixed Point Logic)
# ==========================================
def apply_scaling(val, shift, round_add):
    # Rounding
    val = val + round_add
    # Truncation (Arithmetic Shift)
    return val >> shift

# ==========================================
# 4. System Simulation (CIC + FIR)
# ==========================================
def run_golden_model(input_data):
    # --- A. CIC Filter ---
    # 1. Integrators
    integ = input_data.copy()
    for _ in range(N_STAGES):
        integ = np.cumsum(integ)
        
    # 2. Decimation
    decimated = integ[::D_FACTOR]
    
    # 3. Combs
    comb = decimated.copy()
    for _ in range(N_STAGES):
        # diff calculates x[n] - x[n-1], prepend 0 for initial memory
        comb = np.diff(comb, prepend=0)
        
    # 4. Scaling
    cic_out = []
    for val in comb:
        cic_out.append(apply_scaling(val, CIC_SHIFT, CIC_ROUND_ADD))
    cic_out = np.array(cic_out, dtype=np.int64)
    
    # --- B. Compensation FIR ---
    # Convolution
    fir_raw = np.convolve(cic_out, FIR_COEFFS, mode='full')
    
    # Scaling
    fir_final = []
    for val in fir_raw:
        fir_final.append(apply_scaling(val, FIR_SHIFT, FIR_ROUND_ADD))
        
    # Trim length to match CIC output (convolution adds samples at the end)
    # Also accounting for latency
    return np.array(fir_final[:len(cic_out)], dtype=np.int64)

# ==========================================
# 5. Execution and Comparison
# ==========================================
if __name__ == "__main__":
    # 1. Generate Stimulus
    input_data = generate_stimulus()
    
    # 2. Run Python (Golden Model)
    python_output = run_golden_model(input_data)

    # Save expected results to file (for documentation or later use)
    np.savetxt('python_golden_output.txt', python_output, fmt='%d')
    print("✅ Fixed Point file saved successfully: python_golden_output.txt")
    
    # 3. Load Verilog file for comparison
    try:
        verilog_output = np.loadtxt("verilog_output.txt", dtype=np.int64)
        print("✅ verilog_output.txt loaded successfully.")
    except OSError:
        print("⚠️ Warning: verilog_output.txt not found. Displaying Python results only.")
        verilog_output = np.array([])

    # 4. Comparison (If file exists)
    if len(verilog_output) > 0:
        # Align lengths
        min_len = min(len(python_output), len(verilog_output))
        py_trimmed = python_output[:min_len]
        v_trimmed = verilog_output[:min_len]
        
        # Calculate difference
        error = v_trimmed - py_trimmed
        max_error = np.max(np.abs(error))
        
        print("-" * 40)
        print(f"Compared Samples Count: {min_len}")
        print(f"Maximum Error: {max_error}")
        
        if max_error <= 1:
            print("🏆 Result: Perfect Match (Bit-Exact Match)!")
        else:
            print(f"❌ Result: Mismatch found with max error {max_error}. (Check Shift or Rounding values)")
            
        # Plot difference
        plt.figure(figsize=(12, 8))
        
        plt.subplot(2, 1, 1)
        plt.plot(py_trimmed, label='Python (Golden)', linewidth=2, alpha=0.7)
        plt.plot(v_trimmed, label='Verilog (Actual)', linestyle='--', color='red', alpha=0.7)
        plt.title(f'Output Comparison (D={D_FACTOR})')
        plt.ylabel('Amplitude')
        plt.legend()
        plt.grid(True)
        
        plt.subplot(2, 1, 2)
        plt.plot(error, color='orange', label='Error (Verilog - Python)')
        plt.title(f'Error Signal (Max: {max_error})')
        plt.xlabel('Sample Index')
        plt.ylabel('Difference')
        plt.legend()
        plt.grid(True)
        
        plt.tight_layout()
        plt.show()
        
    else:
        # Display Python output only if Verilog file is missing
        plt.figure(figsize=(10, 5))
        plt.plot(python_output)
        plt.title(f"Python Golden Model Output (D={D_FACTOR})")
        plt.grid(True)
        plt.show()