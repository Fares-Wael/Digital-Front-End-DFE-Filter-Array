// Standard Controllable IIR BiQuad (Direct Form II Transposed)
// All fixed-point calculations use high-precision accumulation (ACC_W=64)

`timescale 1ns / 1ps

module IIR_BiQuad_Controllable #(parameter COEFF_W = 16,DATA_W = 16,ACC_W = 64)(
    input wire clk,
    input wire rst_n,
    input wire signed [DATA_W-1:0] x,
    output reg signed [DATA_W-1:0] y,
    
    // Dynamic Coefficient Inputs from Control Register File
    input wire signed [COEFF_W-1:0] a1_coeff,
    input wire signed [COEFF_W-1:0] a2_coeff,
    input wire signed [COEFF_W-1:0] b0_coeff,
    input wire signed [COEFF_W-1:0] b1_coeff,
    input wire signed [COEFF_W-1:0] b2_coeff
);
    // Parameters
   
    localparam STATE_W = ACC_W; 
    localparam MULTIP = COEFF_W + STATE_W; // Multiplier output width (80 bits)

    // Rounding Constant (2^(Q-1) = 2^14 = 16384 for Q=15)
    localparam signed [ACC_W-1:0] ROUND_BIAS = 64'd16384; 
    localparam Q_SHIFT = 15; // The fractional precision

    // Delay Registers (States) - Storing high-precision rounded values
    reg signed [STATE_W-1:0] s1, s2;

    // Wire Of Multiplication (Full multiplier width)
    wire signed [MULTIP-1:0] a1s1, a2s2, b0w0, b1s1, b2s2;
    
    // --- Combinational Logic ---
    
    // 1. Input Sign Extension (x is s16.15, extended to ACC_W, NO SHIFT)
    wire signed [ACC_W-1:0] x_ext = {{ACC_W-DATA_W{x[DATA_W-1]}}, x}; 

    // 2. Compute w0_acc (Direct Form II Transposed - Input Path)
    // Multiplication outputs are truncated to ACC_W for accumulation 
    assign a1s1 = a1_coeff * s1;
    assign a2s2 = a2_coeff * s2;

    wire signed [ACC_W-1:0] w0_acc = x_ext - a1s1[ACC_W-1:0] - a2s2[ACC_W-1:0]; 

    // 3. Rounding for w0 to s16.15 precision (Shift right by Q_SHIFT)
    // Symmetric rounding: (Acc + Bias) >> Q_SHIFT
    wire signed [STATE_W-1:0] w0_rounded = (w0_acc + ROUND_BIAS) >>> Q_SHIFT; 

    // 4. Compute y_acc (Direct Form II Transposed - Output Path)
    assign b0w0 = b0_coeff * w0_rounded;
    assign b1s1 = b1_coeff * s1;
    assign b2s2 = b2_coeff * s2;
    
    wire signed [ACC_W-1:0] y_acc = b0w0[ACC_W-1:0] + b1s1[ACC_W-1:0] + b2s2[ACC_W-1:0];

    // 5. Rounding for y_acc to s16.15 precision
    wire signed [ACC_W-1:0] y_rounded = (y_acc + ROUND_BIAS) >>> Q_SHIFT;

    // 6. Saturation For Output y (Clip to 16-bit range: 0x7FFF / 0x8000)
    wire signed [DATA_W-1:0] y_saturated = (y_rounded >= 16'h7FFF)? 16'h7FFF:
                                            (y_rounded < 16'h8000)? 16'h8000:
                                            y_rounded[DATA_W-1:0]; 

    // --- Sequential Part ---
    always@(posedge clk,negedge rst_n) begin
        if(!rst_n)begin
            s1 <= 0;
            s2 <= 0;
            y <= 0;
        end
        else begin
            // Update States
            s2 <= s1;
            s1 <= w0_rounded; // Store the high-precision rounded value
            // Output
            y <= y_saturated;
        end
    end

endmodule