// This module encapsulates the CIC Decimator and the Compensation FIR
// Provided by the user.

`timescale 1ns / 1ps
//`include "cic_modules.v" // Assuming user's cic_filter and compensation_fir are here

module CIC_Compensation_Chain #(
    parameter INPUT_WIDTH = 16,
    parameter N_STAGES = 4,
    parameter D_MAX = 16
)(
    input wire clk,
    input wire reset_n,
    input wire signed [INPUT_WIDTH-1:0] data_in,
    input wire [2:0] D_select, // Decimation factor select
    
    output wire signed [INPUT_WIDTH-1:0] data_out,
    output wire data_valid,
    output wire cic_overflow // Assuming cic_filter has an overflow output
);
    
    // Internal wires connecting CIC and FIR
    wire signed [INPUT_WIDTH-1:0] w_cic_data;
    wire w_cic_valid; 

    // Assuming the user's cic_filter module has an overflow output
    wire w_cic_overflow_internal; 
    assign cic_overflow = w_cic_overflow_internal;

    // 1. CIC Filter Instantiation
    cic_filter #(
        .N_STAGES(N_STAGES),
        .INPUT_WIDTH(INPUT_WIDTH),
        .D_MAX(D_MAX)
    ) u_cic_inst (
        .clk(clk),
        .reset_n(reset_n),
        .data_in(data_in),    
        .D_select(D_select),  
        
        .data_out(w_cic_data),   
        .data_valid(w_cic_valid),
        // Assuming overflow output is added to user's cic_filter module
        .o_overflow(w_cic_overflow_internal) 
    );

    // 2. Compensation FIR Instantiation
    compensation_fir #(
        .INPUT_WIDTH(INPUT_WIDTH),
        .OUTPUT_WIDTH(INPUT_WIDTH)
    ) u_fir_inst (
        .clk(clk),
        .reset_n(reset_n),
        .data_in(w_cic_data),
        .data_in_valid(w_cic_valid),
        
        .data_out(data_out),
        .data_out_valid(data_valid)
    );

endmodule