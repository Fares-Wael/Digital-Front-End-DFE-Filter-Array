// Cascaded dual IIR Notch filters (2.4 MHz then 5.0 MHz)
// Coefficients are provided externally by the Control Register File.

`timescale 1ns / 1ps
//`include "iir_biquad.v"

module IIR_Notch_Array_Controllable #( parameter DATA_W = 16,COEFF_W = 16,ACC_W = 64) (
    input wire clk,
    input wire rst_n,
    input wire signed [DATA_W-1:0] x,
    output wire signed [DATA_W-1:0] y,
    input wire bypass, // Bypass the entire Notch stage

    // 2.4 MHz Notch Coefficients (Example addresses 0x14-0x24)
    input wire signed [COEFF_W-1:0] a1_2m4_coeff,
    input wire signed [COEFF_W-1:0] a2_2m4_coeff,
    input wire signed [COEFF_W-1:0] b0_2m4_coeff,
    input wire signed [COEFF_W-1:0] b1_2m4_coeff,
    input wire signed [COEFF_W-1:0] b2_2m4_coeff,

    // 5.0 MHz Notch Coefficients (Example addresses 0x08-0x18)
    input wire signed [COEFF_W-1:0] a1_5m_coeff,
    input wire signed [COEFF_W-1:0] a2_5m_coeff,
    input wire signed [COEFF_W-1:0] b0_5m_coeff,
    input wire signed [COEFF_W-1:0] b1_5m_coeff,
    input wire signed [COEFF_W-1:0] b2_5m_coeff,

    output wire signed [DATA_W-1:0] debug_output 
);
   


    wire signed [DATA_W-1:0] data_mid;
    wire signed [DATA_W-1:0] y_filtered;

    // --- Filter 1: 2.4 MHz Notch ---
    IIR_BiQuad_Controllable #(
        .DATA_W(DATA_W), .COEFF_W(COEFF_W), .ACC_W(ACC_W)
    ) u_notch_2_4mhz (
        .clk(clk), .rst_n(rst_n), .x(x), .y(data_mid),
        .a1_coeff(a1_2m4_coeff),
        .a2_coeff(a2_2m4_coeff),
        .b0_coeff(b0_2m4_coeff),
        .b1_coeff(b1_2m4_coeff),
        .b2_coeff(b2_2m4_coeff)
    );

    // --- Filter 2: 5.0 MHz Notch ---
    IIR_BiQuad_Controllable #(
        .DATA_W(DATA_W), .COEFF_W(COEFF_W), .ACC_W(ACC_W)
    ) u_notch_5_0mhz (
        .clk(clk), .rst_n(rst_n), .x(data_mid), .y(y_filtered),
        .a1_coeff(a1_5m_coeff),
        .a2_coeff(a2_5m_coeff),
        .b0_coeff(b0_5m_coeff),
        .b1_coeff(b1_5m_coeff),
        .b2_coeff(b2_5m_coeff)
    );

    // Bypass Logic
    assign y = bypass ? x : y_filtered;
    assign debug_output = y_filtered; // Output of the filters
    
endmodule