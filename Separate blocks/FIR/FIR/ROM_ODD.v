// ============================================================
// Odd Phase Coefficients ROM - PARALLEL OUTPUT (6x 16-bit)
// Total Taps: 114 (Divided into 19 chunks of 6)
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