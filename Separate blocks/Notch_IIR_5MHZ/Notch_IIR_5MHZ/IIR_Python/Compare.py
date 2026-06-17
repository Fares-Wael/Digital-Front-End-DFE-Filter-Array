import numpy as np
import matplotlib.pyplot as plt

# --- 1. Configuration ---
# Output file paths
PYTHON_OUTPUT_FILE = "python_output_float.txt"
VERILOG_OUTPUT_FILE = "verilog_output_fixed.txt"
# Fixed-point format used in Verilog (s16.15)
Q_BITS = 15
Q_SCALE = 2**Q_BITS

# --- 2. Load Data ---
try:
    # Load Golden Model output (floating point values)
    y_golden_float = np.loadtxt(PYTHON_OUTPUT_FILE)

    # Load Verilog output (16-bit integer values)
    y_verilog_fixed_int = np.loadtxt(
        VERILOG_OUTPUT_FILE, dtype=np.int16)  # Read as s16 integer

    # Convert Verilog values from fixed-point integer to floating point for comparison
    y_verilog_float = y_verilog_fixed_int / Q_SCALE

except FileNotFoundError as e:
    print(f"Error: One of the output files not found: {e}")
    print("Please ensure 'python_output_float.txt' and 'verilog_output_fixed.txt' are in the same directory.")
    exit()

# Ensure both arrays have the same length for accurate comparison
min_len = min(len(y_golden_float), len(y_verilog_float))
y_golden_float = y_golden_float[:min_len]
y_verilog_float = y_verilog_float[:min_len]

# --- 3. Calculate Error Metrics ---
# Calculate error vector
error = y_golden_float - y_verilog_float
absolute_error = np.abs(error)
rmse = np.sqrt(np.mean(error**2))  # Calculate Root Mean Square Error
max_abs_error = np.max(absolute_error)
mean_abs_error = np.mean(absolute_error)

# Print comparison results
print("\n--- Comparison Results ---")
print(f"Number of samples compared: {min_len}")
print(f"Root Mean Square Error (RMSE): {rmse:.8f}")
print(f"Maximum Absolute Error: {max_abs_error:.8f}")
print(f"Mean Absolute Error: {mean_abs_error:.8f}")

# --- 4. Plotting ---
plt.figure(figsize=(12, 8))

# Subplot 1: Comparison of Outputs
plt.subplot(2, 1, 1)  # 2 rows, 1 column, first plot
plt.plot(y_golden_float, label='Python Golden Model', color='blue')
plt.plot(y_verilog_float, label='Verilog Fixed-Point Output',
         linestyle='--', color='red', alpha=0.7)
plt.title('Comparison of Filter Outputs (Python vs Verilog)')
plt.xlabel('Sample Number')
plt.ylabel('Amplitude')
plt.legend()
plt.grid(True)
# Zooming on the first 100 samples to see details clearly
plt.xlim(0, 100)

# Subplot 2: Absolute Error
plt.subplot(2, 1, 2)  # 2 rows, 1 column, second plot
# Plot the absolute error
plt.plot(absolute_error, label='Absolute Error |Golden - Verilog|', color='green')
plt.title(
    f'Absolute Error (Max Abs Error: {max_abs_error:.8f}, RMSE: {rmse:.8f})')
plt.xlabel('Sample Number')
plt.ylabel('Absolute Error')
plt.legend()
plt.grid(True)
# Zooming on the first 100 samples
plt.xlim(0, 100)

plt.tight_layout()  # Adjust plot layout
plt.show()

# --- 5. Additional Plot: Full Signal Comparison ---
plt.figure(figsize=(12, 4))
plt.plot(y_golden_float, label='Python Golden Model', color='blue')
plt.plot(y_verilog_float, label='Verilog Fixed-Point Output',
         linestyle='--', alpha=0.7, color='red')
plt.title('Full Signal Comparison (Python vs Verilog)')
plt.xlabel('Sample Number')
plt.ylabel('Amplitude')
plt.legend()
plt.grid(True)
plt.show()
