// This file contains the structural framework for the DFE system,
// integrating all modules: Clock Gen, Fractional, Notch Array, CIC Chain, and Control.

`timescale 1ns / 1ps

// Include all necessary modules
/*`include "iir_notch_array.v"
`include "control_reg_file.v"
`include "cic_chain.v"
`include "frac_deci.v" 
`include "clock_gen.v"*/

// ====================================================================
// 1. TOP LEVEL MODULE (DFE_TOP)
// ====================================================================
module DFE_TOP #(parameter DATA_W = 16,COEFF_W = 16,ACC_W = 64,
                 N_STAGES_CIC = 4,D_MAX_CIC = 16,PADDR_W = 8,PWDATA_W = 32) (
    // Clock & Reset
    input wire clk_9mhz,      // Master Clock (9 MHz)
    input wire rst_n,         // Active-low reset
    
    // Data Path (9 MHz input -> CIC output)
    input wire in_valid,            // Input data valid (9 MHz domain)
    input wire signed [DATA_W-1:0] data_in_9mhz,
    output wire signed [DATA_W-1:0] data_out_cic,
    output wire out_valid_cic,      // Final output valid flag

    // Control Path (APB-Lite Simplified Interface)
    input wire apb_pwrite,    // Write Enable (PWRITE)
    input wire apb_psel,      // Selection/Enable (PSEL)
    input wire [PADDR_W-1:0] apb_paddr, // Address
    input wire [PWDATA_W-1:0] apb_pwdata, // Write Data
    output wire [PWDATA_W-1:0] apb_prdata, // Read Data
    output wire apb_pready    // Ready signal
);

    // --- Internal Clock Signal ---
    wire clk_6mhz; // Derived clock signal

    // --- Control Register Outputs ---
    wire control_bypass_notch;
    wire [1:0] control_cic_factor; // Factor D select (2 bits used by CIC_CHAIN for now)
    wire [COEFF_W-1:0] notch_coeff_a1_5mhz, notch_coeff_a2_5mhz, notch_coeff_b0_5mhz, notch_coeff_b1_5mhz, notch_coeff_b2_5mhz;
    wire [COEFF_W-1:0] notch_coeff_a1_2m4, notch_coeff_a2_2m4, notch_coeff_b0_2m4, notch_coeff_b1_2m4, notch_coeff_b2_2m4;

    // --- Internal Status/Status Inputs to Control Reg File ---
    wire frac_out_valid; // Output valid from Fractional Decimator
    wire cic_overflow;
    wire [DATA_W-1:0] debug_notch_output; 

    // --- Data Path Signals ---
    wire signed [DATA_W-1:0] data_out_frac; // 6 MHz stream
    wire signed [DATA_W-1:0] data_out_notch; // 6 MHz stream
    wire out_valid_notch;

    // =================================================================
    // 1. Clock Generator (9 MHz -> 6 MHz)
    // =================================================================
    Clock_Generator_PH i_clock_gen (
        .clk_9mhz(clk_9mhz),
        .clk_6mhz(clk_6mhz)
    );

    // =================================================================
    // 2. Control Register File (APB Slave) - Clocked by clk_6mhz
    // =================================================================
    Control_Reg_File #(
        .DATA_W(DATA_W), .COEFF_W(COEFF_W), .PADDR_W(PADDR_W), .PWDATA_W(PWDATA_W)
    ) i_control_reg_file (
        // Bus Interface
        .clk(clk_6mhz), .rst_n(rst_n), .apb_pwrite(apb_pwrite), .apb_psel(apb_psel),
        .apb_paddr(apb_paddr), .apb_pwdata(apb_pwdata), .apb_prdata(apb_prdata), .apb_pready(apb_pready),

        // Control Outputs (5 MHz Notch)
        .o_bypass_notch(control_bypass_notch),
        .o_cic_factor(control_cic_factor),
        .o_notch_a1_5m(notch_coeff_a1_5mhz), .o_notch_a2_5m(notch_coeff_a2_5mhz), .o_notch_b0_5m(notch_coeff_b0_5mhz),
        .o_notch_b1_5m(notch_coeff_b1_5mhz), .o_notch_b2_5m(notch_coeff_b2_5mhz),
        
        // Control Outputs (2.4 MHz Notch)
        .o_notch_a1_2m4(notch_coeff_a1_2m4), .o_notch_a2_2m4(notch_coeff_a2_2m4), .o_notch_b0_2m4(notch_coeff_b0_2m4),
        .o_notch_b1_2m4(notch_coeff_b1_2m4), .o_notch_b2_2m4(notch_coeff_b2_2m4),

        // Status Inputs
        .i_cic_overflow(cic_overflow),
        .i_frac_ready(frac_out_valid), // Use frac output valid as ready signal
        .i_debug_data(debug_notch_output)
    );

    // =================================================================
    // 3. Fractional Decimator (9 MHz -> 6 MHz) - Clock Crossing
    // =================================================================
    Frac_Deci #(
        .DATA_WIDTH(DATA_W)
        // Note: N_TAPS, CHUNK_SIZE, NUM_CHUNK are hardcoded in Frac_Deci.v
    ) u_frac_dec (
        .clk_in(clk_9mhz),
        .clk_out(clk_6mhz),
        .rst_n(rst_n),
        .in_valid(in_valid),
        .in_data(data_in_9mhz),
        .out_valid(frac_out_valid),
        .out_data(data_out_frac)
    );

    // =================================================================
    // 4. Dual IIR Notch Filters (6 MHz)
    // =================================================================
    IIR_Notch_Array_Controllable #(
        .DATA_W(DATA_W), .COEFF_W(COEFF_W), .ACC_W(ACC_W)
    ) u_notch_filters (
        .clk(clk_6mhz),
        .rst_n(rst_n),
        .x(data_out_frac), // Input from Fractional Decimator
        .y(data_out_notch), // Output to CIC
        .bypass(control_bypass_notch), // Controlled by Reg File
        
        // 5 MHz Coefficients
        .a1_5m_coeff(notch_coeff_a1_5mhz), .a2_5m_coeff(notch_coeff_a2_5mhz), .b0_5m_coeff(notch_coeff_b0_5mhz),
        .b1_5m_coeff(notch_coeff_b1_5mhz), .b2_5m_coeff(notch_coeff_b2_5mhz),

        // 2.4 MHz Coefficients
        .a1_2m4_coeff(notch_coeff_a1_2m4), .a2_2m4_coeff(notch_coeff_a2_2m4), .b0_2m4_coeff(notch_coeff_b0_2m4),
        .b1_2m4_coeff(notch_coeff_b1_2m4), .b2_2m4_coeff(notch_coeff_b2_2m4),
        
        .debug_output(debug_notch_output) // Status/Debug probe
    );

    // =================================================================
    // 5. CIC Decimator Chain (6 MHz -> 6 MHz/D)
    // =================================================================
    CIC_Compensation_Chain #(
        .INPUT_WIDTH(DATA_W),
        .N_STAGES(N_STAGES_CIC),
        .D_MAX(D_MAX_CIC)
    ) u_cic_chain (
        .clk(clk_6mhz),
        .reset_n(rst_n),
        .data_in(data_out_notch),
        .D_select(control_cic_factor), // Controlled by Reg File
        
        .data_out(data_out_cic),
        .data_valid(out_valid_cic),
        .cic_overflow(cic_overflow) // Status output
    );

endmodule