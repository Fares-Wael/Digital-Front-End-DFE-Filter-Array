`timescale 1ns / 1ps

module tb_sine_wave;

    //  Settings and Definitions
    parameter INPUT_WIDTH  = 16;
    parameter CLK_PERIOD   = 10; // 100 MHz

    // File handle definition (must be declared here with other definitions)
    integer file_handle;

    reg clk;
    reg reset_n;
    reg signed [INPUT_WIDTH-1:0] system_in;
    reg [2:0] D_select;

    wire signed [INPUT_WIDTH-1:0] system_out;
    wire system_valid;

    // Auxiliary variables for Sine calculation
    real PI = 3.14159265358979;
    real amplitude = 30000.0; 
    real freq_rad = 0;        
    real freq_step;           
    real sin_val_float;       

    //  System Connection (DUT)
    dfe_top #(
        .INPUT_WIDTH(16),
        .N_STAGES(4),
        .D_MAX(16)
    ) u_dut (
        .clk(clk),
        .reset_n(reset_n),
        .system_in(system_in),
        .D_select(D_select),
        .system_out(system_out),
        .system_valid(system_valid)
    );

    //  Clock Generator
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    //  Sine Wave Scenario (Main Control)
    initial begin
        // A. Open file for writing
        file_handle = $fopen("verilog_output.txt", "w");
        if (file_handle == 0) begin
            $display("Error: Could not open output file!");
            $stop;
        end

        $display("=== Sine Wave Simulation Started ===");
        
        // B. Initialization
        reset_n = 0;
        system_in = 0;
        D_select = 3'b010; // Working with D=4
        freq_rad = 0;
        
        // Angle change speed
        freq_step = 0.05; 

        #(CLK_PERIOD * 10);
        reset_n = 1;

        // C. Wave Generation Loop
        repeat(2000) begin
            @(negedge clk); // Wait for clock edge
            
            // 1. Calculate Sine
            sin_val_float = $sin(freq_rad);
            
            // 2. Convert to Fixed Point
            system_in = sin_val_float * amplitude;

            // 3. Increment Angle
            freq_rad = freq_rad + freq_step;
            if (freq_rad > 2*PI) freq_rad = freq_rad - 2*PI;
        end
        
        // D. End Simulation and Close File
        $display("=== Simulation Finished ===");
        $display("Closing file...");
        $fclose(file_handle); // Closing the file here is essential
        $stop;
    end

    // File Writing Block (Independent)
    // Write value only when system_valid is 1
    always @(posedge clk) begin
        if (system_valid) begin
            // Write number to file in Decimal format
            $fdisplay(file_handle, "%d", $signed(system_out));
        end
    end

endmodule