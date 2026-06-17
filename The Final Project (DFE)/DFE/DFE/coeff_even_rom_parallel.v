// Fractional Decimator (Frac_Deci) and its ROMs provided by the user.

`timescale 1ns / 1ps

// ============================================================
// Even Phase Coefficients ROM - PARALLEL OUTPUT (6x 16-bit)
// ============================================================
module coeff_even_rom_parallel (
    input  [6:0] addr,                       // Base Address of the chunk (0, 6, 12, ... up to 108)
    
    // Output: 6 parallel coefficients (Discrete Ports)
    output reg signed [15:0] coeff_0,        // Coefficient 0
    output reg signed [15:0] coeff_1,        // Coefficient 1
    output reg signed [15:0] coeff_2,        // Coefficient 2
    output reg signed [15:0] coeff_3,        // Coefficient 3
    output reg signed [15:0] coeff_4,        // Coefficient 4
    output reg signed [15:0] coeff_5         // Coefficient 5
);

// Combinational logic block (always @(*)) reads 6 coefficients in parallel
always @ (*) begin
    // Default assignment to avoid latches and ensure known state
    coeff_0 = 16'h0000;
    coeff_1 = 16'h0000;
    coeff_2 = 16'h0000;
    coeff_3 = 16'h0000;
    coeff_4 = 16'h0000;
    coeff_5 = 16'h0000;

    case (addr)
        // -------------------------------------------------------------
        // CHUNK 0: Addr = 0. Taps: 0 to 5
        // -------------------------------------------------------------
        7'd0: begin
            coeff_0 = 16'h0000; 
            coeff_1 = 16'hFFFE; 
            coeff_2 = 16'hFFF9; 
            coeff_3 = 16'hFFFE; 
            coeff_4 = 16'h0005; 
            coeff_5 = 16'hFFFE; 
        end
        
        // -------------------------------------------------------------
        // CHUNK 1: Addr = 6. Taps: 6 to 11
        // -------------------------------------------------------------
        7'd6: begin
            coeff_0 = 16'hFFFB; 
            coeff_1 = 16'h0008; 
            coeff_2 = 16'hFFFE; 
            coeff_3 = 16'hFFF6; 
            coeff_4 = 16'h000C; 
            coeff_5 = 16'h0001; 
        end
        
        // -------------------------------------------------------------
        // CHUNK 2: Addr = 12. Taps: 12 to 17
        // -------------------------------------------------------------
        7'd12: begin
            coeff_0 = 16'hFFEF; 
            coeff_1 = 16'h0011; 
            coeff_2 = 16'h0006; 
            coeff_3 = 16'hFFE3; 
            coeff_4 = 16'h0017; 
            coeff_5 = 16'h000E; 
        end
        
        // -------------------------------------------------------------
        // CHUNK 3: Addr = 18. Taps: 18 to 23
        // -------------------------------------------------------------
        7'd18: begin
            coeff_0 = 16'hFFD4; 
            coeff_1 = 16'h001C; 
            coeff_2 = 16'h001B; 
            coeff_3 = 16'hFFBF; 
            coeff_4 = 16'h0021; 
            coeff_5 = 16'h002F; 
        end
        
        // -------------------------------------------------------------
        // CHUNK 4: Addr = 24. Taps: 24 to 29
        // -------------------------------------------------------------
        7'd24: begin
            coeff_0 = 16'hFFA4; 
            coeff_1 = 16'h0025; 
            coeff_2 = 16'h004C; 
            coeff_3 = 16'hFF83; 
            coeff_4 = 16'h0025; 
            coeff_5 = 16'h0073; 
        end
        
        // -------------------------------------------------------------
        // CHUNK 5: Addr = 30. Taps: 30 to 35
        // -------------------------------------------------------------
        7'd30: begin
            coeff_0 = 16'hFF5B; 
            coeff_1 = 16'h0020; 
            coeff_2 = 16'h00A8; 
            coeff_3 = 16'hFF2A; 
            coeff_4 = 16'h0013; 
            coeff_5 = 16'h00F0; 
        end

        // -------------------------------------------------------------
        // CHUNK 6: Addr = 36. Taps: 36 to 41
        // -------------------------------------------------------------
        7'd36: begin
            coeff_0 = 16'hF9EF; 
            coeff_1 = 16'hFFFC; 
            coeff_2 = 16'h014F; 
            coeff_3 = 16'hFEA6; 
            coeff_4 = 16'hFFD5; 
            coeff_5 = 16'h01D1; 
        end

        // -------------------------------------------------------------
        // CHUNK 7: Addr = 42. Taps: 42 to 47
        // -------------------------------------------------------------
        7'd42: begin
            coeff_0 = 16'hFE4B; 
            coeff_1 = 16'hFF95; 
            coeff_2 = 16'h028B; 
            coeff_3 = 16'hFDD1; 
            coeff_4 = 16'hFF2A; 
            coeff_5 = 16'h03A9; 
        end

        // -------------------------------------------------------------
        // CHUNK 8: Addr = 48. Taps: 48 to 53
        // -------------------------------------------------------------
        7'd48: begin
            coeff_0 = 16'hFD19; 
            coeff_1 = 16'hFE68; 
            coeff_2 = 16'h05AB; 
            coeff_3 = 16'hFBC5; 
            coeff_4 = 16'hFCB3; 
            coeff_5 = 16'h0AA8; 
        end

        // -------------------------------------------------------------
        // CHUNK 9: Addr = 54. Taps: 54 to 59
        // -------------------------------------------------------------
        7'd54: begin
            coeff_0 = 16'hF7CC; 
            coeff_1 = 16'hF549; 
            coeff_2 = 16'h3648; 
            coeff_3 = 16'h509A; 
            coeff_4 = 16'h1124; 
            coeff_5 = 16'hEE05; 
        end

        // -------------------------------------------------------------
        // CHUNK 10: Addr = 60. Taps: 60 to 65
        // -------------------------------------------------------------
        7'd60: begin
            coeff_0 = 16'h054F; 
            coeff_1 = 16'h0589; 
            coeff_2 = 16'hF888; 
            coeff_3 = 16'h023F; 
            coeff_4 = 16'h0371; 
            coeff_5 = 16'hFB82; 
        end

        // -------------------------------------------------------------
        // CHUNK 11: Addr = 66. Taps: 66 to 71
        // -------------------------------------------------------------
        7'd66: begin
            coeff_0 = 16'h0127; 
            coeff_1 = 16'h0280; 
            coeff_2 = 16'hFCF8; 
            coeff_3 = 16'h009A; 
            coeff_4 = 16'h01ED; 
            coeff_5 = 16'hFDDB; 
        end

        // -------------------------------------------------------------
        // CHUNK 12: Addr = 72. Taps: 72 to 77
        // -------------------------------------------------------------
        7'd72: begin
            coeff_0 = 16'h0047; 
            coeff_1 = 16'h0185; 
            coeff_2 = 16'hFE75; 
            coeff_3 = 16'h0015; 
            coeff_4 = 16'h0134; 
            coeff_5 = 16'hFEE4; 
        end

        // -------------------------------------------------------------
        // CHUNK 13: Addr = 78. Taps: 78 to 83
        // -------------------------------------------------------------
        7'd78: begin
            coeff_0 = 16'hFFF7; 
            coeff_1 = 16'h00F2; 
            coeff_2 = 16'hFF37; 
            coeff_3 = 16'hFFE6; 
            coeff_4 = 16'h00BD; 
            coeff_5 = 16'hFF74; 
        end
        
        // -------------------------------------------------------------
        // CHUNK 14: Addr = 84. Taps: 84 to 89
        // -------------------------------------------------------------
        7'd84: begin
            coeff_0 = 16'hFFDD; 
            coeff_1 = 16'h0090; 
            coeff_2 = 16'hFFA2; 
            coeff_3 = 16'hFFDB; 
            coeff_4 = 16'h006B; 
            coeff_5 = 16'hFFC3; 
        end

        // -------------------------------------------------------------
        // CHUNK 15: Addr = 90. Taps: 90 to 95
        // -------------------------------------------------------------
        7'd90: begin
            coeff_0 = 16'hFFDD; 
            coeff_1 = 16'h004E; 
            coeff_2 = 16'hFFDB; 
            coeff_3 = 16'hFFE1; 
            coeff_4 = 16'h0036; 
            coeff_5 = 16'hFFEC; 
        end

        // -------------------------------------------------------------
        // CHUNK 16: Addr = 96. Taps: 96 to 101
        // -------------------------------------------------------------
        7'd96: begin
            coeff_0 = 16'hFFE6; 
            coeff_1 = 16'h0024; 
            coeff_2 = 16'hFFF7; 
            coeff_3 = 16'hFFEC; 
            coeff_4 = 16'h0017; 
            coeff_5 = 16'hFFFD; 
        end
        
        // -------------------------------------------------------------
        // CHUNK 17: Addr = 102. Taps: 102 to 107
        // -------------------------------------------------------------
        7'd102: begin
            coeff_0 = 16'hFFF2; 
            coeff_1 = 16'h000D; 
            coeff_2 = 16'h0001; 
            coeff_3 = 16'hFFF6; 
            coeff_4 = 16'h0007; 
            coeff_5 = 16'h0002; 
        end

        // -------------------------------------------------------------
        // CHUNK 18: Addr = 108. Taps: 108 to 113 (LAST CHUNK)
        // -------------------------------------------------------------
        7'd108: begin
            coeff_0 = 16'hFFFA; 
            coeff_1 = 16'h0003; 
            coeff_2 = 16'h0003; 
            coeff_3 = 16'hFFFA; 
            coeff_4 = 16'hFFFB; 
            coeff_5 = 16'hFFFF; 
        end

        default: begin
            // Default Case: essential for synthesis
            coeff_0 = 16'h0000;
            coeff_1 = 16'h0000;
            coeff_2 = 16'h0000;
            coeff_3 = 16'h0000;
            coeff_4 = 16'h0000;
            coeff_5 = 16'h0000;
        end
    endcase
end
endmodule


// ============================================================
// Odd Phase Coefficients ROM - PARALLEL OUTPUT (6x 16-bit)
// ============================================================
module coeff_odd_rom_parallel (
    input  [6:0] addr,                       // Base Address of the chunk (0, 6, 12, ... up to 108)
    
    // Output: 6 parallel coefficients (Discrete Ports)
    output reg signed [15:0] coeff_0,        // Coefficient 0
    output reg signed [15:0] coeff_1,        // Coefficient 1
    output reg signed [15:0] coeff_2,        // Coefficient 2
    output reg signed [15:0] coeff_3,        // Coefficient 3
    output reg signed [15:0] coeff_4,        // Coefficient 4
    output reg signed [15:0] coeff_5         // Coefficient 5
);

// Combinational logic block (always @(*)) reads 6 coefficients in parallel
always @ (*) begin
    // Default assignment
    coeff_0 = 16'h0000;
    coeff_1 = 16'h0000;
    coeff_2 = 16'h0000;
    coeff_3 = 16'h0000;
    coeff_4 = 16'h0000;
    coeff_5 = 16'h0000;

    case (addr)
        // -------------------------------------------------------------
        // CHUNK 0: Addr = 0. Taps: 0 to 5
        // -------------------------------------------------------------
        7'd0: begin
            coeff_0 = 16'hFFFF; // H[1]
            coeff_1 = 16'hFFFB; // H[3]
            coeff_2 = 16'hFFFA; // H[5]
            coeff_3 = 16'h0003; // H[7]
            coeff_4 = 16'h0003; // H[9]
            coeff_5 = 16'hFFFA; // H[11]
        end
        
        // -------------------------------------------------------------
        // CHUNK 1: Addr = 6. Taps: 6 to 11
        // -------------------------------------------------------------
        7'd6: begin
            coeff_0 = 16'h0002; 
            coeff_1 = 16'h0007; 
            coeff_2 = 16'hFFF6; 
            coeff_3 = 16'h0001; 
            coeff_4 = 16'h000D; 
            coeff_5 = 16'hFFF2; 
        end
        
        // -------------------------------------------------------------
        // CHUNK 2: Addr = 12. Taps: 12 to 17
        // -------------------------------------------------------------
        7'd12: begin
            coeff_0 = 16'hFFFD; 
            coeff_1 = 16'h0017; 
            coeff_2 = 16'hFFEC; 
            coeff_3 = 16'hFFF7; 
            coeff_4 = 16'h0024; 
            coeff_5 = 16'hFFE6; 
        end
        
        // -------------------------------------------------------------
        // CHUNK 3: Addr = 18. Taps: 18 to 23
        // -------------------------------------------------------------
        7'd18: begin
            coeff_0 = 16'hFFEC; 
            coeff_1 = 16'h0036; 
            coeff_2 = 16'hFFE1; 
            coeff_3 = 16'hFFDB; 
            coeff_4 = 16'h004E; 
            coeff_5 = 16'hFFDD; 
        end
        
        // -------------------------------------------------------------
        // CHUNK 4: Addr = 24. Taps: 24 to 29
        // -------------------------------------------------------------
        7'd24: begin
            coeff_0 = 16'hFFC3; 
            coeff_1 = 16'h006B; 
            coeff_2 = 16'hFFDB; 
            coeff_3 = 16'hFFA2; 
            coeff_4 = 16'h0090; 
            coeff_5 = 16'hFFDD; 
        end

        // -------------------------------------------------------------
        // CHUNK 5: Addr = 30. Taps: 30 to 35
        // -------------------------------------------------------------
        7'd30: begin
            coeff_0 = 16'hFF74; 
            coeff_1 = 16'h00BD; 
            coeff_2 = 16'hFFE6; 
            coeff_3 = 16'hFF37; 
            coeff_4 = 16'h00F2; 
            coeff_5 = 16'hFFF7; 
        end

        // -------------------------------------------------------------
        // CHUNK 6: Addr = 36. Taps: 36 to 41
        // -------------------------------------------------------------
        7'd36: begin
            coeff_0 = 16'hFEE4; 
            coeff_1 = 16'h0134; 
            coeff_2 = 16'h0015; 
            coeff_3 = 16'hFE75; 
            coeff_4 = 16'h0185; 
            coeff_5 = 16'h0047; 
        end

        // -------------------------------------------------------------
        // CHUNK 7: Addr = 42. Taps: 42 to 47
        // -------------------------------------------------------------
        7'd42: begin
            coeff_0 = 16'hFDDB; 
            coeff_1 = 16'h01ED; 
            coeff_2 = 16'h009A; 
            coeff_3 = 16'hFCF8; 
            coeff_4 = 16'h0280; 
            coeff_5 = 16'h0127; 
        end

        // -------------------------------------------------------------
        // CHUNK 8: Addr = 48. Taps: 48 to 53
        // -------------------------------------------------------------
        7'd48: begin
            coeff_0 = 16'hFB82; 
            coeff_1 = 16'h0371; 
            coeff_2 = 16'h023F; 
            coeff_3 = 16'hF888; 
            coeff_4 = 16'h0589; 
            coeff_5 = 16'h054F; 
        end

        // -------------------------------------------------------------
        // CHUNK 9: Addr = 54. Taps: 54 to 59
        // -------------------------------------------------------------
        7'd54: begin
            coeff_0 = 16'hEE05; 
            coeff_1 = 16'h1124; 
            coeff_2 = 16'h509A; 
            coeff_3 = 16'h3648; 
            coeff_4 = 16'hF549; 
            coeff_5 = 16'hF7CC; 
        end

        // -------------------------------------------------------------
        // CHUNK 10: Addr = 60. Taps: 60 to 65
        // -------------------------------------------------------------
        7'd60: begin
            coeff_0 = 16'h0AA8; 
            coeff_1 = 16'hFCB3; 
            coeff_2 = 16'hFBC5; 
            coeff_3 = 16'h05AB; 
            coeff_4 = 16'hFE68; 
            coeff_5 = 16'hFD19; 
        end

        // -------------------------------------------------------------
        // CHUNK 11: Addr = 66. Taps: 66 to 71
        // -------------------------------------------------------------
        7'd66: begin
            coeff_0 = 16'h03A9; 
            coeff_1 = 16'hFF2A; 
            coeff_2 = 16'hFDD1; 
            coeff_3 = 16'h028B; 
            coeff_4 = 16'hFF95; 
            coeff_5 = 16'hFE4B; 
        end

        // -------------------------------------------------------------
        // CHUNK 12: Addr = 72. Taps: 72 to 77
        // -------------------------------------------------------------
        7'd72: begin
            coeff_0 = 16'h01D1; 
            coeff_1 = 16'hFFD5; 
            coeff_2 = 16'hFEA6; 
            coeff_3 = 16'h014F; 
            coeff_4 = 16'hFFFC; 
            coeff_5 = 16'hFEEF; 
        end

        // -------------------------------------------------------------
        // CHUNK 13: Addr = 78. Taps: 78 to 83
        // -------------------------------------------------------------
        7'd78: begin
            coeff_0 = 16'h00F0; 
            coeff_1 = 16'h0013; 
            coeff_2 = 16'hFF2A; 
            coeff_3 = 16'h00A8; 
            coeff_4 = 16'h0020; 
            coeff_5 = 16'hFF5B; 
        end
        
        // -------------------------------------------------------------
        // CHUNK 14: Addr = 84. Taps: 84 to 89
        // -------------------------------------------------------------
        7'd84: begin
            coeff_0 = 16'h0073; 
            coeff_1 = 16'h0025; 
            coeff_2 = 16'hFF83; 
            coeff_3 = 16'h004C; 
            coeff_4 = 16'h0025; 
            coeff_5 = 16'hFFA4; 
        end

        // -------------------------------------------------------------
        // CHUNK 15: Addr = 90. Taps: 90 to 95
        // -------------------------------------------------------------
        7'd90: begin
            coeff_0 = 16'h002F; 
            coeff_1 = 16'h0021; 
            coeff_2 = 16'hFFBF; 
            coeff_3 = 16'h001B; 
            coeff_4 = 16'h001C; 
            coeff_5 = 16'hFFD4; 
        end

        // -------------------------------------------------------------
        // CHUNK 16: Addr = 96. Taps: 96 to 101
        // -------------------------------------------------------------
        7'd96: begin
            coeff_0 = 16'h000E; 
            coeff_1 = 16'h0017; 
            coeff_2 = 16'hFFE3; 
            coeff_3 = 16'h0006; 
            coeff_4 = 16'h0011; 
            coeff_5 = 16'hFFEF; 
        end
        
        // -------------------------------------------------------------
        // CHUNK 17: Addr = 102. Taps: 102 to 107
        // -------------------------------------------------------------
        7'd102: begin
            coeff_0 = 16'h0001; 
            coeff_1 = 16'h000C; 
            coeff_2 = 16'hFFF6; 
            coeff_3 = 16'hFFFE; 
            coeff_4 = 16'h0008; 
            coeff_5 = 16'hFFFB; 
        end

        // -------------------------------------------------------------
        // CHUNK 18: Addr = 108. Taps: 108 to 113 (LAST CHUNK)
        // -------------------------------------------------------------
        7'd108: begin
            coeff_0 = 16'hFFFE; 
            coeff_1 = 16'h0005; 
            coeff_2 = 16'hFFFE; 
            coeff_3 = 16'hFFF9; 
            coeff_4 = 16'hFFFE; 
            coeff_5 = 16'h0000; 
        end

        default: begin
            // Default Case
            coeff_0 = 16'h0000;
            coeff_1 = 16'h0000;
            coeff_2 = 16'h0000;
            coeff_3 = 16'h0000;
            coeff_4 = 16'h0000;
            coeff_5 = 16'h0000;
        end
    endcase
end
endmodule


// ============================================================
// Fractional Decimator (9 MHz -> 6 MHz)
// Corrected module name and clock ports for DFE_TOP integration
// ============================================================
module Frac_Deci #( parameter DATA_WIDTH = 16) (
    input wire clk_in, 
    input wire clk_out,
    input wire rst_n, 
    input wire in_valid, 
    input wire signed [DATA_WIDTH - 1 : 0] in_data, 
    output reg out_valid, 
    output reg signed [DATA_WIDTH - 1 : 0] out_data
);
    //--------------------
    // Parameters
    //--------------------
    parameter COEFF_WIDTH = 16;
    parameter N_TAPS = 228;
    parameter FRAC_BITS = 15;
    parameter CHUNK_SIZE = 6;
    parameter NUM_CHUNK = 19;
    parameter ACC_WIDTH = DATA_WIDTH + COEFF_WIDTH + $clog2(N_TAPS); // ~40 bits

    localparam signed [ACC_WIDTH-1:0] MAX_Q15 =  32767;
    localparam signed [ACC_WIDTH-1:0] MIN_Q15 = -32768;

    //--------------------
    // Internal Signals
    //--------------------
    reg phase_sel;
    wire [6 : 0] coeff_add;
    wire signed [ACC_WIDTH - 1 : 0] chunk_sum;
    reg [4 : 0] mac_chunk_add;
    reg signed [ACC_WIDTH - 1 : 0] phase_0_sum;
    reg signed [ACC_WIDTH - 1 : 0] phase_1_sum;
    
    // Control Signals
    reg mac_active;
    reg [1:0] decim_cnt; // 0, 1, 2

    // Parallel MAC Signals
    wire signed [ACC_WIDTH - 1 : 0] chunk_products [CHUNK_SIZE - 1 : 0];
    wire signed [COEFF_WIDTH - 1 : 0] parallel_even_coeff [CHUNK_SIZE - 1 : 0];
    wire signed [COEFF_WIDTH - 1 : 0] parallel_odd_coeff [CHUNK_SIZE - 1 : 0];
    
    // Loop Variables
    integer i;
    genvar j;

    // ROM Wires
    wire signed [COEFF_WIDTH - 1 : 0] even_coeff_0, even_coeff_1, even_coeff_2, even_coeff_3, even_coeff_4, even_coeff_5;
    wire signed [COEFF_WIDTH - 1 : 0] odd_coeff_0, odd_coeff_1, odd_coeff_2, odd_coeff_3, odd_coeff_4, odd_coeff_5;

    // Output Combinational Signals (Rounding & Saturation)
    wire signed [ACC_WIDTH:0] total_sum;
    wire signed [ACC_WIDTH:0] rounded_sum;
    wire signed [ACC_WIDTH:0] shifted_sum;
    reg signed [DATA_WIDTH-1:0] saturated_val;

    //--------------------
    // ROMs Instantiation
    //--------------------
    coeff_even_rom_parallel even_rom (
        .addr(coeff_add), 
        .coeff_0(even_coeff_0), .coeff_1(even_coeff_1), .coeff_2(even_coeff_2),
        .coeff_3(even_coeff_3), .coeff_4(even_coeff_4), .coeff_5(even_coeff_5)
    );

    coeff_odd_rom_parallel odd_rom (
        .addr(coeff_add), 
        .coeff_0(odd_coeff_0), .coeff_1(odd_coeff_1), .coeff_2(odd_coeff_2),
        .coeff_3(odd_coeff_3), .coeff_4(odd_coeff_4), .coeff_5(odd_coeff_5)
    );

    //------------------------------
    // Delay Lines
    //------------------------------
    reg signed [DATA_WIDTH - 1 : 0] delay_line_shift_reg [N_TAPS - 1 : 0];
    reg signed [DATA_WIDTH - 1 : 0] delay_snapshot [N_TAPS - 1 : 0];

    //------------------------------
    // COMBINATIONAL LOGIC: Output Calculation
    //------------------------------
    // 1. Sum Phase 0 + Phase 1
    assign total_sum = phase_0_sum + phase_1_sum;

    // 2. Rounding (Add 0.5 LSB = 1 << 14)
    assign rounded_sum = total_sum + (1 <<< (FRAC_BITS - 1));

    // 3. Truncation (Shift Right by 15)
    assign shifted_sum = rounded_sum >>> FRAC_BITS;

    // 4. Saturation Logic
    always @(*) begin
        if (shifted_sum > 32767) 
            saturated_val = 16'h7FFF;
        else if (shifted_sum < -32768) 
            saturated_val = 16'h8000;
        else 
            saturated_val = shifted_sum[15:0];
    end

    //------------------------------
    // Main Sequential Logic (9 MHz domain)
    //------------------------------
    always @ (posedge clk_in, negedge rst_n) begin
        if (! rst_n) begin
            // Reset all signals
            phase_sel <= 0;
            mac_chunk_add <= 0;
            phase_0_sum <= 0;
            phase_1_sum <= 0;
            mac_active <= 0;
            decim_cnt <= 0;
            
            for (i = 0; i < N_TAPS ; i = i + 1) begin
                delay_line_shift_reg[i] <= 0;
                delay_snapshot[i] <= 0;
            end
        end

        else begin
            // --------------------------------------------------
            // 1. Data Path: Shift & Load (Always runs on in_valid)
            // --------------------------------------------------
            if (in_valid) begin
                for (i = N_TAPS- 1; i > 0 ; i = i - 1) begin
                    delay_line_shift_reg[i] <= delay_line_shift_reg[i - 1];
                end
                delay_line_shift_reg[0] <= in_data;

                // Increment Decimation Counter (Modulo 3)
                if (decim_cnt == 2) 
                    decim_cnt <= 0;
                else 
                    decim_cnt <= decim_cnt + 1;
            end

            // --------------------------------------------------
            // 2. Control Path: Start MAC (Triggered by in_valid)
            // --------------------------------------------------
            if (in_valid && !mac_active) begin
                // Take Snapshot
                for (i = 0; i < N_TAPS; i = i + 1) begin
                    delay_snapshot[i] <= delay_line_shift_reg[i];
                end

                // Start MAC
                mac_active <= 1'b1;
                phase_sel <= 1'b0; // Phase 0
                mac_chunk_add <= 0;
                phase_0_sum <= 0;
                phase_1_sum <= 0;
            end
            
            // --------------------------------------------------
            // 3. MAC Execution Path
            // --------------------------------------------------
            if (mac_active) begin
                if (mac_chunk_add < NUM_CHUNK) begin
                    // Accumulate
                    if (phase_sel == 1'b0) 
                        phase_0_sum <= phase_0_sum + chunk_sum;
                    else 
                        phase_1_sum <= phase_1_sum + chunk_sum;

                    mac_chunk_add <= mac_chunk_add + 1;
                end
                else begin // End of Phase (Chunk count = 19)
                    mac_chunk_add <= 0;

                    if (phase_sel == 1'b0) begin
                        phase_sel <= 1'b1; // Go to Phase 1
                    end 
                    else begin
                        // End of Phase 1 -> Finish Calculation
                        mac_active <= 0;
                        phase_sel <= 0;
                        
                        // Output Latching is done on clk_out (6 MHz domain)
                    end
                end
            end
        end
    end

    //--------------------------------------------------
    // Output Sequential Logic (6 MHz domain)
    //--------------------------------------------------
    always @(posedge clk_out or negedge rst_n) begin
        if (!rst_n) begin
            out_valid <= 0;
            out_data <= 0;
        end else begin
            // Latch the calculated output on the slower clock (6 MHz)
            // This assumes proper clock domain crossing (CDC) setup in a real system.
            if (mac_active == 0 && phase_sel == 1'b1) begin
                // Calculation finished in 9 MHz domain
                if (decim_cnt == 0) begin // Decimate by 3 (output every 3rd sample)
                    out_valid <= 1'b1;
                    out_data <= saturated_val; 
                end else begin
                    out_valid <= 1'b0;
                end
            end else begin
                 out_valid <= 1'b0;
            end
        end
    end


    //--------------------------------------------------
    // Assignments & Generating Logic
    //--------------------------------------------------
    assign coeff_add = mac_chunk_add * CHUNK_SIZE;

    // Map wires to arrays for cleaner indexing in generate
    assign parallel_even_coeff[0] = even_coeff_0;
    assign parallel_even_coeff[1] = even_coeff_1;
    assign parallel_even_coeff[2] = even_coeff_2;
    assign parallel_even_coeff[3] = even_coeff_3;
    assign parallel_even_coeff[4] = even_coeff_4;
    assign parallel_even_coeff[5] = even_coeff_5;

    assign parallel_odd_coeff[0] = odd_coeff_0;
    assign parallel_odd_coeff[1] = odd_coeff_1;
    assign parallel_odd_coeff[2] = odd_coeff_2;
    assign parallel_odd_coeff[3] = odd_coeff_3;
    assign parallel_odd_coeff[4] = odd_coeff_4;
    assign parallel_odd_coeff[5] = odd_coeff_5;

    // Parallel MACs
    generate
        for (j = 0; j < CHUNK_SIZE; j = j + 1) begin : PMAC
            wire [7:0] k_index_full = (mac_chunk_add * CHUNK_SIZE) + j;
            wire [8:0] abs_index = (k_index_full << 1) | phase_sel; // Polyphase Indexing

            wire signed [COEFF_WIDTH - 1 : 0] current_coeff = phase_sel ? parallel_odd_coeff[j] : parallel_even_coeff[j];

            assign chunk_products[j] = delay_snapshot[abs_index] * current_coeff;
        end
    endgenerate

    assign chunk_sum = chunk_products[0] + chunk_products[1] + chunk_products[2] + 
                       chunk_products[3] + chunk_products[4] + chunk_products[5];

endmodule