module Notch_IIR(clk,rst_n,x,y);
  // Parameters
  parameter COEFF_W = 16;
  parameter DATA_W = 16;
  parameter STATE_W = 48;
  parameter ACC_W = 64;
  localparam MULTIP = COEFF_W + STATE_W;
  // Rounding Constant
  localparam signed [ACC_W-1:0] ROUND_BIAS = 64'd16384; // 2^(Q-1) == 2^(15-1) == 2^14  
  // Filter Coefficients According To Q1.15 Fixed Point
      // a0 Coefficient is always 1 so does'nt Affect In Multiplication
  parameter signed [COEFF_W-1:0] a1 = -31932;
  parameter signed [COEFF_W-1:0] a2 = 31096;
  parameter signed [COEFF_W-1:0] b0 = 31932;
  parameter signed [COEFF_W-1:0] b1 = -31932;
  parameter signed [COEFF_W-1:0] b2 = 31932;
  // Ports
  input clk,rst_n;
  input signed [DATA_W-1:0] x;
  output reg signed [DATA_W-1:0] y;

  // Delay Registers (States)
  reg signed [STATE_W-1:0] s1;
  reg signed [STATE_W-1:0] s2;

  // Wire Of Multiplication
  wire signed [MULTIP-1:0] a1s1;
  wire signed [MULTIP-1:0] a2s2;
  wire signed [MULTIP-1:0] b0w0;
  wire signed [MULTIP-1:0] b1s1;
  wire signed [MULTIP-1:0] b2s2;

  // Design Flow
  // to make x wide to make it easy to deal with it
  wire signed [ACC_W-1:0] x_ext = {{49{x[15]}},x[14:0]} <<< 15; // Sign Extention cuz verilog does not do it auto when using Shift

  // Filter Multiplications (Feedback)
  assign a1s1 = a1 * s1;
  assign a2s2 = a2 * s2;

  wire signed [ACC_W-1:0] w0_acc = x_ext - a1s1 - a2s2; // Compute w0 = x - a1*s1 - a2*s2
  // Rounding for w0 to convert it to Q15
  wire signed [ACC_W-1:0] w0_rounded = (w0_acc >= 0)?((w0_acc + ROUND_BIAS) >>> 15):
                                                       ((w0_acc - ROUND_BIAS) >>> 15);

  /*// Saturate w0_acc to STATE_W   
  wire signed [STATE_W-1:0] w0_saturated = (w0_rounded >= 48'h7FFF_FFFF_FFFF)? 48'h7FFF_FFFF_FFFF:
                                           (w0_rounded < -48'h8000_0000_0000)? -48'h8000_0000_0000:
                                                                               w0_rounded[47:0];    */                                              
  // Filter Multiplications (Feedforward)
  assign b0w0 = b0 * w0_rounded;
  assign b1s1 = b1 * s1;
  assign b2s2 = b2 * s2;
  // Compute y = b0w0 + b1s1 + b2s2 
  wire signed [ACC_W-1:0] y_acc = b0w0 + b1s1 + b2s2;

  // Rounding to y_acc to convert it to Q15
  wire signed [ACC_W-1:0] y_rounded = (y_acc >= 0)?((y_acc + ROUND_BIAS) >>> 15):
                                                     ((y_acc - ROUND_BIAS) >>> 15);

  // Saturation For Output y
  wire signed [DATA_W-1:0] y_saturated = (y_rounded >= 32767)?16'd32767:
                                         (y_rounded < -32768)?-16'd32768:y_rounded[15:0]; 


  // Sequitial Part
  always@(posedge clk,negedge rst_n) begin
      if(!rst_n)begin
        s1 <= 0;
        s2 <= 0;
        y <= 0;
      end
      else begin
        // Update Status
        s2 <= s1;
        s1 <= w0_rounded;
        // Output
        y <= y_saturated;
      end
  end

endmodule
   