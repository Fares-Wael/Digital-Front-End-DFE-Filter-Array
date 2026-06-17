module Notch_IIR_2_4 (
    input wire clk,
    input wire rst_n,
    input  wire signed [15:0] x,
    output reg  signed [15:0] y
);

    // Q1.15 coefficients
    parameter signed [15:0] b0 = 16'sd31932;
    parameter signed [15:0] b1 = 16'sd32767;
    parameter signed [15:0] b2 = 16'sd31932;

    parameter signed [15:0] a1 = 16'sd18899;   // +0.5767
    parameter signed [15:0] a2 = 16'sd31096;   // +0.9489

    // States (Q1.15)
    reg signed [31:0] w1, w2;

    // Multiply helper (Q1.15 × Q1.15 → Q1.15 with rounding)
    function signed [31:0] q15_mult;
        input signed [15:0] a, b;
        reg signed [31:0] m;
    begin
        m = a * b;          // Q30
        m = m + 32'sd16384; // rounding bias
        q15_mult = m >>> 15; // back to Q15
    end
    endfunction

    // Saturation function
    function signed [15:0] sat16;
        input signed [31:0] v;
    begin
        if (v > 32767)      sat16 = 32767;
        else if (v < -32768) sat16 = -32768;
        else                sat16 = v[15:0];
    end
    endfunction

    reg signed [31:0] w0;
    reg signed [31:0] y_calc;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            w1 <= 0;
            w2 <= 0;
            y  <= 0;
        end else begin
            
            // === internal state w0 ===
            w0 = x
                 - q15_mult(a1, w1[15:0])
                 - q15_mult(a2, w2[15:0]);

            // === output ===
            y_calc =
                  q15_mult(b0, w0[15:0])
                + q15_mult(b1, w1[15:0])
                + q15_mult(b2, w2[15:0]);

            y <= sat16(y_calc);

            // === update states ===
            w2 <= w1;
            w1 <= w0;
        end
    end

endmodule