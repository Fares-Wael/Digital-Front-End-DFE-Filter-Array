// Testbench focused on isolation and external file input loading.

`timescale 1ns / 1ps

module DFE_TOP_tb;

    // --- System Parameters ---
    parameter DATA_W = 16;
    parameter PADDR_W = 8;
    parameter PWDATA_W = 32;
    parameter ACC_W = 64;
    
    // Clock Periods (Manual Generation for Simulation)
    parameter T_9MHZ = 111; // 1 / 9 MHz approx 111.11 ns
    parameter T_6MHZ = 166; // 1 / 6 MHz approx 166.66 ns

    // --- Signals ---
    reg clk_sys;
    reg clk_9mhz;
    reg rst_n;
    
    // DFE Data I/O
    reg in_valid;
    reg signed [DATA_W-1:0] data_in_9mhz;
    wire signed [DATA_W-1:0] data_out_cic;
    wire out_valid_cic;

    // APB Bus Signals
    reg apb_pwrite;
    reg apb_psel;
    reg [PADDR_W-1:0] apb_paddr;
    reg [PWDATA_W-1:0] apb_pwdata;
    wire [PWDATA_W-1:0] apb_prdata;
    wire apb_pready;

    // File I/O Variables
    integer file_in;
    integer file_out; // NEW: Output file handle
    integer status;
    reg [15:0] hex_data_in; // Variable to hold 16-bit hex data read from file

    // Counters
    integer i;
    
    // --- Clock Generation ---
    initial begin
        clk_9mhz = 0;
        forever #(T_9MHZ/2) clk_9mhz = ~clk_9mhz;
    end
    initial begin
        // Arbitrary faster clock for APB synchronization (was clk_sys)
        clk_sys = 0; 
        forever #(T_9MHZ/4) clk_sys = ~clk_sys; 
    end
    
    // 6 MHz Clock Generation (Internal signals)
    reg clk_6mhz_internal_reg; // Register holding the 6 MHz clock value
    wire clk_6mhz_internal;    // Wire to connect 6 MHz clock
    
    initial begin
        clk_6mhz_internal_reg = 0;
        forever #(T_6MHZ/2) clk_6mhz_internal_reg = ~clk_6mhz_internal_reg;
    end
    
    // Correct connection of the internal clock wire
    assign clk_6mhz_internal = clk_6mhz_internal_reg; 

    // --- Instantiate DUT ---
    DFE_TOP #(
        .DATA_W(DATA_W), .COEFF_W(DATA_W), .ACC_W(ACC_W),
        .N_STAGES_CIC(4), .D_MAX_CIC(16),
        .PADDR_W(PADDR_W), .PWDATA_W(PWDATA_W)
    ) DUT (
        .clk_9mhz(clk_9mhz),
        .rst_n(rst_n),
        .in_valid(in_valid),
        .data_in_9mhz(data_in_9mhz),
        .data_out_cic(data_out_cic),
        .out_valid_cic(out_valid_cic),
        .apb_pwrite(apb_pwrite),
        .apb_psel(apb_psel),
        .apb_paddr(apb_paddr),
        .apb_pwdata(apb_pwdata),
        .apb_prdata(apb_prdata),
        .apb_pready(apb_pready)
    );
    
    // FIX for Clock Crossing: Force the internal clock output
    initial begin
        // Force the output port clk_6mhz inside the Clock_Generator_PH instance
        force DUT.i_clock_gen.clk_6mhz = clk_6mhz_internal;
    end
    
    // --- Tasks for APB Write (Synchronized to clk_9mhz for simplicity) ---
    task apb_write;
        input [PADDR_W-1:0] addr;
        input [PWDATA_W-1:0] wdata;
        begin
            @(posedge clk_9mhz); // Sync write to the clock that drives the Control Unit (clk_6mhz)
            apb_psel = 1'b1;
            apb_pwrite = 1'b1;
            apb_paddr = addr;
            apb_pwdata = wdata;
            
            @(posedge clk_9mhz)
            if (!apb_pready) @(posedge clk_9mhz);
            
            apb_psel = 1'b0;
            apb_pwrite = 1'b0;
        end
    endtask

    // --- Main Test Sequence ---
    initial begin
        // --- Setup Dump Files ---
        $dumpfile("dfe_top.vcd");
        $dumpvars(0, DFE_TOP_tb);
        $monitor("Time: %t, CIC_OUT: %d, CIC_VALID: %b, NOTCH_BYPASS: %b",
                 $time, DUT.data_out_cic, DUT.out_valid_cic, DUT.i_control_reg_file.o_bypass_notch);
        
        // --- Open Input/Output Files ---
        file_in = $fopen("input_data.dat", "r");
        file_out = $fopen("dfe_cic_output.txt", "w"); // NEW: Open output file
        
        if (file_in == 0) begin
            $display("ERROR: Could not open input_data.dat for reading.");
            $finish;
        end
        if (file_out == 0) begin
            $display("ERROR: Could not open dfe_cic_output.txt for writing.");
            $finish;
        end
        $display("Input file input_data.dat and output file opened successfully.");
        
        // --- Initialization and Reset ---
        rst_n = 0;
        in_valid = 0;
        data_in_9mhz = 0;
        apb_psel = 0;
        apb_pwrite = 0;
        
        repeat(5) @(posedge clk_9mhz); // Wait 5 cycles
        rst_n = 1; // De-assert reset

        // --- 1. APB Configuration (Run-Time Control) ---
        
        $display("\n--- 1. Configuring Control Registers ---");
        
        // A. Bypass Notch (Initial State: Bypass OFF (0), CIC Factor D=1)
        // Reg ADDR_CONTROL (0x00): Bit[0] = Bypass, Bit[2:1] = CIC Factor (00=D=1)
        apb_write(8'h00, 32'h00000000); 
        $display("Notch Bypass OFF, CIC D=1 (0x00)");

        // B. Set 5.0 MHz Notch Coefficients (Assuming 0x7978, 0x838C for A2, A1)
        apb_write(8'h08, {16'sh7978, 16'sh838C}); // A2, A1 at 0x08
        // Values: b0=31932 (0x7CB4), b1=-31932 (0x838C), b2=31932 (0x7CB4)
        apb_write(8'h0C, {16'sh838C, 16'sh7CB4}); // B1, B0 at 0x0C
        // Note: The control unit assumes b2 is written separately (not implemented here for brevity).

        // --- 2. Data Injection (9 MHz domain) ---
        $display("\n--- 2. Injecting Test Signal from input_data.dat ---");
        
        i = 0;
        // Loop while not at the end of the input file
        while (!$feof(file_in)) begin
            
            // Read one 16-bit hexadecimal value from the file (%h)
            status = $fscanf(file_in, "%h\n", hex_data_in);
            
            if (status == 1) begin // Check if read was successful
                // Apply the 16-bit hex data to the signed input 'data_in_9mhz'
                // The input file contains fixed-point data (s16.15)
                data_in_9mhz = $signed(hex_data_in);
                
                // Apply data and valid flag
                in_valid = 1'b1;
                
                // Wait for the next 9 MHz clock edge
                @(negedge clk_9mhz);
                
                // --- Write Output Logic (Synchronized to 6 MHz clock) ---
                // We write the output ONLY when it is valid
                if (DUT.out_valid_cic) begin
                    // Writing the output value as signed decimal integer
                    $fwrite(file_out, "%d\n", $signed(DUT.data_out_cic)); 
                end
                
                i = i + 1;
            end else if (status != 0) begin
                $display("Warning: File read status check failed or unexpected data format.");
            end
        end
        
        in_valid = 1'b0; // Stop feeding data
        $display("Finished injecting %0d samples from file.", i);

        // --- 3. Observation Period (Wait for pipelines to clear) ---
        // Continue monitoring the 6 MHz domain until the output buffer is drained
        repeat(100) @(posedge clk_6mhz_internal); 
        
        // --- 4. Test Run-Time CIC Factor Change ---
        $display("\n--- 3. Testing CIC Factor Change to D=4 ---");
        
        // CIC D=4 corresponds to control_cic_factor = 2'b10 (Bit 2:1)
        apb_write(8'h00, 32'h00000004); 
        $display("CIC Factor set to D=4 (6 MHz / 4 = 1.5 MHz output rate)");
        
        repeat(50) @(posedge clk_6mhz_internal); // Wait for pipeline to stabilize
        
        // --- 5. Test Notch Bypass ---
        $display("\n--- 4. Testing Notch Bypass ON ---");
        // Bypass ON (Bit 0 = 1, CIC D=4 still active)
        apb_write(8'h00, 32'h00000005); 
        $display("Notch Bypass ON (Expected output quality change)");
        
        repeat(50) @(posedge clk_6mhz_internal); // Wait and observe output change
        
        // --- 6. Cleanup and Finish Simulation ---
        $fclose(file_in);
        $fclose(file_out); // Close the output file
        $display("\n--- Simulation Complete. Output saved to dfe_cic_output.txt ---");
        $finish;
    end
endmodule