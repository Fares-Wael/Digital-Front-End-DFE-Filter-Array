`timescale 1ns / 1ps

module cic_filter #(
    parameter N_STAGES      = 4,   // n_stages > 60db
    parameter INPUT_WIDTH   = 16,  // s16.15 format
    parameter D_MAX         = 16   //  max decimation
)(
    input                            clk,        // 6 MHz Clock
    input                            reset_n,    // asyn active low
    input      signed [INPUT_WIDTH-1:0]  data_in,    // input data
    input      [2:0]                     D_select,   // 000=1, 001=2, 010=4, ...
    
    output reg signed [INPUT_WIDTH-1:0]  data_out,   // output data
    output reg                         data_valid  // output valid flag
);

    
    ///////////////////////////// (Sizing & Growth) /////////////////////////////

    //B_GROWTH = N * log2(D_max)
    localparam B_GROWTH    = N_STAGES * $clog2(D_MAX);
    // SIZE OF ACUUMILATOR
    localparam ACCUM_WIDTH = INPUT_WIDTH + B_GROWTH; // 16 + 16 = 32 bits

    
    ////////////////////////////// (Control Logic) ////////////////////////////////

    reg [$clog2(D_MAX):0]    d_value;      // decimation value
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

    reg signed [ACCUM_WIDTH-1:0] i_regs [0:N_STAGES-1]; // integrators internal registers
    reg [$clog2(D_MAX)-1:0]      counter;               // internal counter
    wire                         tick;                  // steady signal to acceot new data

    ////////////////////////////////// (Sign Extension) //////////////////////////////////
    wire signed [ACCUM_WIDTH-1:0] data_in_ext;
    assign data_in_ext = { {B_GROWTH{data_in[INPUT_WIDTH-1]}}, data_in };

    assign tick = (counter == 0); 

    integer i;
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            counter <= 0;
            for(i=0; i<N_STAGES; i=i+1) i_regs[i] <= 0;
        end else begin
            // (Integrator Chain)
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
    reg signed [ACCUM_WIDTH-1:0] c_comb_out   [0:N_STAGES-1]; // out of difference

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
            // add 0.5
            if (shift_amount > 0)
                rounded_val = c_comb_out[N_STAGES-1] + (1'b1 << (shift_amount-1));
            else
                rounded_val = c_comb_out[N_STAGES-1];

            //(Arithmethic Shift)
            data_out   <= rounded_val >>> shift_amount;
            data_valid <= 1'b1;

        end else begin
            data_valid <= 1'b0;
        end
    end

endmodule