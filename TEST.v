module TEST (clk, rst_n, in_valid, in_data, out_valid, out_data);
    //--------------------
    // Parameters
    //--------------------
    parameter DATA_WIDTH = 16;
    parameter COEFF_WIDTH = 16;
    parameter N_TAPS = 228;
    parameter FRAC_BITS = 15;
    parameter CHUNK_SIZE = 6;
    parameter NUM_CHUNK = 19;
    parameter ACC_WIDTH = DATA_WIDTH + COEFF_WIDTH + $clog2(N_TAPS); // ~40 bits

    localparam signed [ACC_WIDTH-1:0] MAX_Q15 =  32767;
    localparam signed [ACC_WIDTH-1:0] MIN_Q15 = -32768;

    //--------------------
    // Inputs
    //--------------------
    input clk;
    input rst_n;
    input in_valid;
    input signed [DATA_WIDTH - 1 : 0] in_data;

    //--------------------
    // Outputs
    //--------------------
    output reg out_valid;
    output reg signed [DATA_WIDTH - 1 : 0] out_data;
    
    //--------------------
    // Internal Signals
    //--------------------
    reg phase_sel;
    wire [6 : 0] coeff_add;
    wire signed [ACC_WIDTH - 1 : 0] chunk_sum;
    reg [4 : 0] mac_chunk_add;
    reg signed [ACC_WIDTH - 1 : 0] phase_0_sum;
    reg signed [ACC_WIDTH - 1 : 0] phase_1_sum;
    
    // Control Signals
    reg mac_active;
    reg [1:0] decim_cnt; // 0, 1, 2

    // Parallel MAC Signals
    wire signed [ACC_WIDTH - 1 : 0] chunk_products [CHUNK_SIZE - 1 : 0];
    wire signed [COEFF_WIDTH - 1 : 0] parallel_even_coeff [CHUNK_SIZE - 1 : 0];
    wire signed [COEFF_WIDTH - 1 : 0] parallel_odd_coeff [CHUNK_SIZE - 1 : 0];
    
    // Loop Variables
    integer i;
    genvar j;

    // ROM Wires
    wire signed [COEFF_WIDTH - 1 : 0] even_coeff_0, even_coeff_1, even_coeff_2, even_coeff_3, even_coeff_4, even_coeff_5;
    wire signed [COEFF_WIDTH - 1 : 0] odd_coeff_0, odd_coeff_1, odd_coeff_2, odd_coeff_3, odd_coeff_4, odd_coeff_5;

    // Output Combinational Signals (Rounding & Saturation)
    wire signed [ACC_WIDTH:0] total_sum;
    wire signed [ACC_WIDTH:0] rounded_sum;
    wire signed [ACC_WIDTH:0] shifted_sum;
    reg signed [DATA_WIDTH-1:0] saturated_val;

    //--------------------
    // ROMs Instantiation
    //--------------------
    coeff_even_rom_parallel even_rom (
        .addr(coeff_add), 
        .coeff_0(even_coeff_0), .coeff_1(even_coeff_1), .coeff_2(even_coeff_2),
        .coeff_3(even_coeff_3), .coeff_4(even_coeff_4), .coeff_5(even_coeff_5)
    );

    coeff_odd_rom_parallel odd_rom (
        .addr(coeff_add), 
        .coeff_0(odd_coeff_0), .coeff_1(odd_coeff_1), .coeff_2(odd_coeff_2),
        .coeff_3(odd_coeff_3), .coeff_4(odd_coeff_4), .coeff_5(odd_coeff_5)
    );

    //------------------------------
    // Delay Lines
    //------------------------------
    reg signed [DATA_WIDTH - 1 : 0] delay_line_shift_reg [N_TAPS - 1 : 0];
    reg signed [DATA_WIDTH - 1 : 0] delay_snapshot [N_TAPS - 1 : 0];

    //------------------------------
    // COMBINATIONAL LOGIC: Output Calculation
    //------------------------------
    // 1. Sum Phase 0 + Phase 1
    assign total_sum = phase_0_sum + phase_1_sum;

    // 2. Rounding (Add 0.5 LSB = 1 << 14)
    assign rounded_sum = total_sum + (1 <<< (FRAC_BITS - 1));

    // 3. Truncation (Shift Right by 15)
    assign shifted_sum = rounded_sum >>> FRAC_BITS;

    // 4. Saturation Logic
    always @(*) begin
        if (shifted_sum > 32767) 
            saturated_val = 16'h7FFF;
        else if (shifted_sum < -32768) 
            saturated_val = 16'h8000;
        else 
            saturated_val = shifted_sum[15:0];
    end

    //------------------------------
    // Main Sequential Logic
    //------------------------------
    always @ (posedge clk, negedge rst_n) begin
        if (! rst_n) begin
            // Reset all signals
            out_valid <= 0;
            out_data <= 0;
            phase_sel <= 0;
            mac_chunk_add <= 0;
            phase_0_sum <= 0;
            phase_1_sum <= 0;
            mac_active <= 0;
            decim_cnt <= 0;
            
            for (i = 0; i < N_TAPS ; i = i + 1) begin
                delay_line_shift_reg[i] <= 0;
                delay_snapshot[i] <= 0;
            end
        end

        else begin
            // --------------------------------------------------
            // 1. Data Path: Shift & Load (Always runs on in_valid)
            // --------------------------------------------------
            if (in_valid) begin
                for (i = N_TAPS- 1; i > 0 ; i = i - 1) begin
                    delay_line_shift_reg[i] <= delay_line_shift_reg[i - 1];
                end
                delay_line_shift_reg[0] <= in_data;

                // Increment Decimation Counter (Modulo 3)
                if (decim_cnt == 2) 
                    decim_cnt <= 0;
                else 
                    decim_cnt <= decim_cnt + 1;
            end

            // --------------------------------------------------
            // 2. Control Path: Start MAC (Triggered by in_valid)
            // --------------------------------------------------
            if (in_valid && !mac_active) begin
                // Take Snapshot
                for (i = 0; i < N_TAPS; i = i + 1) begin
                    delay_snapshot[i] <= delay_line_shift_reg[i];
                end

                // Start MAC
                mac_active <= 1'b1;
                phase_sel <= 1'b0; // Phase 0
                mac_chunk_add <= 0;
                phase_0_sum <= 0;
                phase_1_sum <= 0;
                
                // Reset output valid (it's a pulse)
                out_valid <= 0; 
            end
            else begin
                 out_valid <= 0; // Default low
            end

            // --------------------------------------------------
            // 3. MAC Execution Path
            // --------------------------------------------------
            if (mac_active) begin
                if (mac_chunk_add < NUM_CHUNK) begin
                    // Accumulate
                    if (phase_sel == 1'b0) 
                        phase_0_sum <= phase_0_sum + chunk_sum;
                    else 
                        phase_1_sum <= phase_1_sum + chunk_sum;

                    mac_chunk_add <= mac_chunk_add + 1;
                end
                else begin // End of Phase (Chunk count = 19)
                    mac_chunk_add <= 0;

                    if (phase_sel == 1'b0) begin
                        phase_sel <= 1'b1; // Go to Phase 1
                    end 
                    else begin
                        // End of Phase 1 -> Finish Calculation
                        mac_active <= 0;
                        phase_sel <= 0;
                        
                        // --------------------------------------
                        // 4. Output Latching (Using Combinational Logic)
                        // --------------------------------------
                        // We use the pre-calculated 'saturated_val'
                        
                        if (decim_cnt == 0) begin // Means we just wrapped from 2->0 on this input
                            out_valid <= 1'b1;
                            out_data <= saturated_val; // Use the combinational result
                        end
                    end
                end
            end
        end
    end

    //--------------------------------------------------
    // Assignments & Generating Logic
    //--------------------------------------------------
    assign coeff_add = mac_chunk_add * CHUNK_SIZE;

    // Map wires to arrays for cleaner indexing in generate
    assign parallel_even_coeff[0] = even_coeff_0;
    assign parallel_even_coeff[1] = even_coeff_1;
    assign parallel_even_coeff[2] = even_coeff_2;
    assign parallel_even_coeff[3] = even_coeff_3;
    assign parallel_even_coeff[4] = even_coeff_4;
    assign parallel_even_coeff[5] = even_coeff_5;

    assign parallel_odd_coeff[0] = odd_coeff_0;
    assign parallel_odd_coeff[1] = odd_coeff_1;
    assign parallel_odd_coeff[2] = odd_coeff_2;
    assign parallel_odd_coeff[3] = odd_coeff_3;
    assign parallel_odd_coeff[4] = odd_coeff_4;
    assign parallel_odd_coeff[5] = odd_coeff_5;

    // Parallel MACs
    generate
        for (j = 0; j < CHUNK_SIZE; j = j + 1) begin : PMAC
            wire [7:0] k_index_full = (mac_chunk_add * CHUNK_SIZE) + j;
            wire [8:0] abs_index = (k_index_full << 1) | phase_sel; // Polyphase Indexing

            wire signed [COEFF_WIDTH - 1 : 0] current_coeff = phase_sel ? parallel_odd_coeff[j] : parallel_even_coeff[j];

            assign chunk_products[j] = delay_snapshot[abs_index] * current_coeff;
        end
    endgenerate

    assign chunk_sum = chunk_products[0] + chunk_products[1] + chunk_products[2] + 
                       chunk_products[3] + chunk_products[4] + chunk_products[5];

endmodule