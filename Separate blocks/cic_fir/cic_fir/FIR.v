module compensation_fir #(
    parameter INPUT_WIDTH  = 16,
    parameter OUTPUT_WIDTH = 16
)(
    input                         clk,
    input                         reset_n,
    // output cic
    input                         data_in_valid,
    input  signed [INPUT_WIDTH-1:0] data_in,
    
    // final output
    output reg                    data_out_valid,
    output reg signed [OUTPUT_WIDTH-1:0] data_out
);

    //  (Coefficients) - s1.15 Fixed Point

    //  N=4
    parameter signed [15:0] COEFF_0 = -16'd1024;  
    parameter signed [15:0] COEFF_1 =  16'd0;    
    parameter signed [15:0] COEFF_2 =  16'd18432; // center (1.125 * 16384)
    parameter signed [15:0] COEFF_3 =  16'd0;
    parameter signed [15:0] COEFF_4 = -16'd1024;


    // (Delay Line / Shift Register)

    reg signed [INPUT_WIDTH-1:0] taps [0:4]; 

    // (Multiply & Accumulate)
    //output  multiplication  32bit  (16*16)
    reg signed [31:0] prod_0, prod_1, prod_2, prod_3, prod_4;
    reg signed [31:0] sum;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            taps[0] <= 0; taps[1] <= 0; taps[2] <= 0; taps[3] <= 0; taps[4] <= 0;
            prod_0 <=0; prod_1<=0; prod_2<=0; prod_3<=0; prod_4<=0;
            sum <= 0 ;
            data_out_valid <= 0;
            data_out <= 0;
        end else begin

            if (data_in_valid) begin
                
                // (Shift)
                taps[0] <= data_in;     // new sample
                taps[1] <= taps[0];
                taps[2] <= taps[1];
                taps[3] <= taps[2];
                taps[4] <= taps[3];

                // (Multiply)
                prod_0 <= taps[0] * COEFF_0;
                prod_1 <= taps[1] * COEFF_1;
                prod_2 <= taps[2] * COEFF_2;
                prod_3 <= taps[3] * COEFF_3;
                prod_4 <= taps[4] * COEFF_4;

                // addition (Accumulate)
                sum <= prod_0 + prod_1 + prod_2 + prod_3 + prod_4;

                //  (Scaling to 16-bit)
    
                data_out <= (sum + 32'd8192) >>> 14; 
                
                data_out_valid <= 1;
            end else begin
                data_out_valid <= 0;
            end
        end
    end

endmodule