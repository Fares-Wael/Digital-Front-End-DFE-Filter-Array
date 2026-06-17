// Modules provided by the user: cic_filter and compensation_fir.

`timescale 1ns / 1ps

// ============================================================
// CIC FILTER MODULE (Updated to include overflow output)
// ============================================================
module cic_filter #(
    parameter N_STAGES      = 4,    // n_stages > 60db
    parameter INPUT_WIDTH   = 16,  // s16.15 format
    parameter D_MAX         = 16    // max decimation
)(
    input                      clk,      // 6 MHz Clock
    input                      reset_n,  // asyn active low
    input       signed [INPUT_WIDTH-1:0]  data_in,    // input data
    input       [2:0]                     D_select,  // 000=1, 001=2, 010=4, ...
    
    output reg signed [INPUT_WIDTH-1:0] data_out,    // output data
    output reg                          data_valid, // output valid flag
    output wire                         o_overflow // NEW: Overflow flag for Control Block
);

    
    ///////////////////////////// (Sizing & Growth) /////////////////////////////

    //B_GROWTH = N * log2(D_max)
    localparam B_GROWTH     = N_STAGES * $clog2(D_MAX);
    // SIZE OF ACUUMILATOR
    localparam ACCUM_WIDTH = (INPUT_WIDTH + B_GROWTH)*2; // 16 + 16 = 32 * 2 =64 bits

    
    ////////////////////////////// (Control Logic) ////////////////////////////////

    reg [$clog2(D_MAX):0]      d_value;     // decimation value
    reg [$clog2(B_GROWTH):0] shift_amount;    // quantity of shift

    always @(*) begin
        case (D_select)
            3'b000: begin d_value = 1;  shift_amount = 0;  end // D=1
            3'b001: begin d_value = 2;  shift_amount = 4;  end // D=2
            3'b010: begin d_value = 4;  shift_amount = 8;  end // D=4
            3'b011: begin d_value = 8;  shift_amount = 12; end // D=8
            3'b100: begin d_value = 16; shift_amount = 16; end // D=16
            default:begin d_value = 1;  shift_amount = 0;  end
        endcase
    end

    
    /////////////////////////////// (Integrators & Counter) ///////////////////////////////
    // Added overflow flag logic
    reg i_overflow_flag;
    assign o_overflow = i_overflow_flag; 

    reg signed [ACCUM_WIDTH-1:0] i_regs [0:N_STAGES-1]; // integrators internal registers
    reg [$clog2(D_MAX)-1:0]      counter;             // internal counter
    wire                          tick;              // steady signal to acceot new data

    ////////////////////////////////// (Sign Extension) //////////////////////////////////
    wire signed [ACCUM_WIDTH-1:0] data_in_ext;
    assign data_in_ext = { {B_GROWTH{data_in[INPUT_WIDTH-1]}}, data_in };

    assign tick = (counter == 0);  

    integer i;
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            counter <= 0;
            i_overflow_flag <= 0; // Reset overflow
            for(i=0; i<N_STAGES; i=i+1) i_regs[i] <= 0;
        end else begin
            // (Integrator Chain)
            // Simple overflow check (MSB == data_in[MSB] and MSB-1 != data_in[MSB-1])
            if (i_regs[0][ACCUM_WIDTH-1] != data_in_ext[ACCUM_WIDTH-1] && i_regs[0][ACCUM_WIDTH-1] == i_regs[0][ACCUM_WIDTH-2]) begin
                 i_overflow_flag <= 1'b1;
            end else begin
                 i_overflow_flag <= 1'b0;
            end
            
            i_regs[0] <= i_regs[0] + data_in_ext;
            for(i=1; i<N_STAGES; i=i+1) begin
                i_regs[i] <= i_regs[i] + i_regs[i-1];
            end

            // (Counter)
            if(tick) counter <= d_value - 1;
            else     counter <= counter - 1;
        end
    end

    ////////////////////////////////// (Combs & Output) /////////////////////////////////

    reg signed [ACCUM_WIDTH-1:0] c_delay_regs [0:N_STAGES-1]; //internal comb registers
    reg signed [ACCUM_WIDTH-1:0] c_comb_out    [0:N_STAGES-1]; // out of difference

    reg signed [ACCUM_WIDTH-1:0] rounded_val;

    integer j;
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            data_valid <= 0;
            data_out   <= 0;
            for(j=0; j<N_STAGES; j=j+1) begin  
                c_delay_regs[j] <= 0; 
                c_comb_out[j]   <= 0; 
            end
        end else if (tick) begin
            //(Comb Chain)

            c_comb_out[0]   <= i_regs[N_STAGES-1] - c_delay_regs[0];
            c_delay_regs[0] <= i_regs[N_STAGES-1];
            
            // another stages
            for(j=1; j<N_STAGES; j=j+1) begin
                c_comb_out[j]   <= c_comb_out[j-1] - c_delay_regs[j];
                c_delay_regs[j] <= c_comb_out[j-1];
            end

            // (Rounding & Scaling)
            // add 0.5 (1 LSB of the output stage)
            if (shift_amount > 0)
                rounded_val = c_comb_out[N_STAGES-1] + (1'b1 << (shift_amount-1));
            else
                rounded_val = c_comb_out[N_STAGES-1];

            //(Arithmethic Shift) - Assuming output is 16-bit wide
            // This shift scales the N-stage output down by the maximum possible gain (R^N)
            data_out   <= rounded_val >>> shift_amount;
            data_valid <= 1'b1;

        end else begin
            data_valid <= 1'b0;
        end
    end

endmodule

// ============================================================
// COMPENSATION FIR MODULE (Provided by the user)
// ============================================================
module compensation_fir #(
    parameter INPUT_WIDTH  = 16,
    parameter OUTPUT_WIDTH = 16
)(
    input                       clk,
    input                       reset_n,
    // output cic
    input                       data_in_valid,
    input  signed [INPUT_WIDTH-1:0] data_in,
    
    // final output
    output reg                  data_out_valid,
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
                taps[0] <= data_in;      // new sample
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
                // Note: The accumulation result is Q30 (15+15) or Q31 (if full multiply width is 16*16=32, Q31)
                // We assume the result is Q30 (1 sign bit + 15 integer bits + 15 fractional bits)
                // Scaling back to Q15 means shifting right by 15. The shift is 14 bits here.
                // Assuming the accumulator is Q31 (1 sign, 16 integer, 15 fractional), 
                // scaling to Q15 means shifting by 15. Shifting by 14 means the output is Q16.
                // We keep the user's shift of 14, which scales by 2^14.
                data_out <= (sum + 32'd8192) >>> 14; 
                
                data_out_valid <= 1;
            end else begin
                data_out_valid <= 0;
            end
        end
    end

endmodule