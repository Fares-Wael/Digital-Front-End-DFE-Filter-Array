// ====================================================================
// 2. CONTROL REGISTER FILE MODULE (APB-Lite Simplified)
// Manages configuration registers and status flags.
// ====================================================================
module Control_Reg_File #(parameter DATA_W = 16,COEFF_W = 16,PADDR_W = 8,PWDATA_W = 32) (
    input wire clk,
    input wire rst_n,

    // APB-Lite Interface
    input wire apb_pwrite,
    input wire apb_psel,
    input wire [PADDR_W-1:0] apb_paddr,
    input wire [PWDATA_W-1:0] apb_pwdata,
    output reg [PWDATA_W-1:0] apb_prdata,
    output reg apb_pready, // APB transaction status

    // Control Outputs
    output reg o_bypass_notch,
    output reg [1:0] o_cic_factor, // Encoded factor D: 00=1, 01=2, 10=4, 11=8 (CIC only uses 3 bits of the user's D_select)
    
    // 5.0 MHz Notch Coefficients (Output)
    output reg [COEFF_W-1:0] o_notch_a1_5m, 
    output reg [COEFF_W-1:0] o_notch_a2_5m,
    output reg [COEFF_W-1:0] o_notch_b0_5m, 
    output reg [COEFF_W-1:0] o_notch_b1_5m,
    output reg [COEFF_W-1:0] o_notch_b2_5m,

    // 2.4 MHz Notch Coefficients (Output)
    output reg [COEFF_W-1:0] o_notch_a1_2m4, 
    output reg [COEFF_W-1:0] o_notch_a2_2m4,
    output reg [COEFF_W-1:0] o_notch_b0_2m4, 
    output reg [COEFF_W-1:0] o_notch_b1_2m4,
    output reg [COEFF_W-1:0] o_notch_b2_2m4,
    
    // Status Inputs
    input wire i_cic_overflow,
    input wire [DATA_W-1:0] i_debug_data, // Read back Notch output
    input wire i_frac_ready
);
    // Parameters defined in DFE_TOP

    // --- Register Map Addresses (Simplified) ---
    localparam ADDR_CONTROL = 8'h00; // Bypass, CIC Factor
    localparam ADDR_STATUS  = 8'h04; // Overflow, Ready
    localparam ADDR_5M_A1 = 8'h08; 
    localparam ADDR_5M_B0 = 8'h0C; 
    localparam ADDR_2M4_A1 = 8'h10;
    localparam ADDR_2M4_B0 = 8'h14;
    localparam ADDR_DEBUG   = 8'h18;

    // --- Internal Register Storage ---
    reg [PWDATA_W-1:0] control_reg_internal;
    reg [PWDATA_W-1:0] status_reg_internal;
    
    // Default 5MHz coefficients (from golden_model.py output)
    localparam signed [COEFF_W-1:0] DEFAULT_A1_5M = -31932;
    localparam signed [COEFF_W-1:0] DEFAULT_B0_5M = 31932;
    // Default 2.4MHz coefficients (from user's Notch_IIR_2_4)
    localparam signed [COEFF_W-1:0] DEFAULT_A1_2M4 = 18899;
    localparam signed [COEFF_W-1:0] DEFAULT_B0_2M4 = 31932;

    // --- APB Write Logic ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            control_reg_internal <= 0;
            // Set defaults for stable startup
            o_notch_a1_5m <= DEFAULT_A1_5M;
            o_notch_b0_5m <= DEFAULT_B0_5M;
            o_notch_a1_2m4 <= DEFAULT_A1_2M4;
            o_notch_b0_2m4 <= DEFAULT_B0_2M4;
            o_notch_a2_5m <= 0; o_notch_b1_5m <= 0; o_notch_b2_5m <= 0;
            o_notch_a2_2m4 <= 0; o_notch_b1_2m4 <= 0; o_notch_b2_2m4 <= 0;
            o_bypass_notch <= 1'b0; 
            o_cic_factor <= 2'b00; // D=1
            apb_pready <= 1'b0;
        end else begin
            apb_pready <= apb_psel; // Simple one-cycle ready response

            if (apb_psel && apb_pwrite) begin
                case (apb_paddr)
                    ADDR_CONTROL: begin
                        control_reg_internal <= apb_pwdata;
                        o_bypass_notch <= apb_pwdata[0];
                        o_cic_factor <= apb_pwdata[2:1];
                    end
                    ADDR_5M_A1: begin o_notch_a1_5m <= apb_pwdata[COEFF_W-1:0]; o_notch_a2_5m <= apb_pwdata[2*COEFF_W-1:COEFF_W]; end // Writing two coeffs in one go (A1, A2)
                    ADDR_5M_B0: begin o_notch_b0_5m <= apb_pwdata[COEFF_W-1:0]; o_notch_b1_5m <= apb_pwdata[2*COEFF_W-1:COEFF_W]; end // Writing two coeffs in one go (B0, B1)
                    // ... other write addresses
                endcase
            end
            
            // Update Status Register (non-reset path)
            status_reg_internal[0] <= i_cic_overflow;
            status_reg_internal[1] <= i_frac_ready;
            status_reg_internal[31:2] <= 30'b0; // Reserved
        end
    end

    // --- APB Read Logic ---
    always @(*) begin
        if (apb_psel && !apb_pwrite) begin
            case (apb_paddr)
                ADDR_CONTROL: apb_prdata = control_reg_internal;
                ADDR_STATUS: apb_prdata = status_reg_internal;
                ADDR_5M_A1: apb_prdata = {o_notch_a2_5m, o_notch_a1_5m}; // Read A2, A1
                ADDR_5M_B0: apb_prdata = {o_notch_b1_5m, o_notch_b0_5m}; // Read B1, B0
                ADDR_DEBUG: apb_prdata = {{PWDATA_W-DATA_W{i_debug_data[DATA_W-1]}}, i_debug_data};
                default: apb_prdata = 0; 
            endcase
        end else begin
            apb_prdata = 0;
        end
    end

endmodule