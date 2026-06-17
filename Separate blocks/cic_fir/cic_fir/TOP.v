`timescale 1ns / 1ps

module dfe_top #(
    parameter INPUT_WIDTH  = 16,
    parameter N_STAGES     = 4,
    parameter D_MAX        = 16
)(
    // --- System Inputs (External) ---
    input         clk,
    input         reset_n,
    input  signed [INPUT_WIDTH-1:0] system_in,   // Raw Data Input
    input  [2:0]  D_select,                      // Speed Selection

    // --- System Outputs (Final) ---
    output signed [INPUT_WIDTH-1:0] system_out,  // Final Data Output
    output        system_valid                   // Final Valid Flag
);

    // 1. Internal Wire Definition (The Bridge)
    // These wires connect the CIC to the FIR inside the module
    wire signed [INPUT_WIDTH-1:0] w_cic_data;  // Wire for Data
    wire                          w_cic_valid; // Wire for Valid Signal

    //  First Instance: CIC Filter
    cic_filter #(
        .N_STAGES(N_STAGES),
        .INPUT_WIDTH(INPUT_WIDTH),
        .D_MAX(D_MAX)
    ) u_cic_inst (
        .clk        (clk),
        .reset_n    (reset_n),
        .data_in    (system_in),    // From External Input
        .D_select   (D_select),     // From External Input
        
        // ** Important Connection Here **
        .data_out   (w_cic_data),   // Output goes to Internal Wire
        .data_valid (w_cic_valid)   // Valid signal goes to Internal Wire
    );

    //  Second Instance: Compensation FIR
    compensation_fir #(
        .INPUT_WIDTH(INPUT_WIDTH),
        .OUTPUT_WIDTH(INPUT_WIDTH)
    ) u_fir_inst (
        .clk            (clk),
        .reset_n        (reset_n),
        
        // ** Reception Here **
        .data_in        (w_cic_data),   // Takes from Internal Wire
        .data_in_valid  (w_cic_valid),  // Takes Valid signal from Internal Wire
        
        // Final Outputs
        .data_out       (system_out),   // Goes to External Output
        .data_out_valid (system_valid)  // Goes to External Output
    );

endmodule