module FRAC_tb;

    // -----------------------
    // Parameters
    // -----------------------
    localparam DATA_WIDTH = 16;

    // -----------------------
    // DUT Signals
    // -----------------------
    reg clk;
    reg rst_n;
    reg in_valid;
    reg signed [DATA_WIDTH - 1 : 0] in_data;
    wire out_valid;
    wire signed [DATA_WIDTH - 1 : 0] out_data;

    // -----------------------
    // File Handles
    // -----------------------
    integer file_in;
    integer file_out;
    integer scan_status;
    reg [DATA_WIDTH-1:0] captured_data;

    // -----------------------
    // Instantiate DUT
    // -----------------------
    Frac_Deci dut (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(in_valid),
        .in_data(in_data),
        .out_valid(out_valid),
        .out_data(out_data)
    );

    // -----------------------
    // Clock Generation
    // -----------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // -----------------------
    // Main Stimulus Process
    // -----------------------
    initial begin
        // 1. تهيئة الإشارات (Blocking Assignments =)
        rst_n = 0;
        in_valid = 0;
        in_data = 0;

        // 2. فتح الملفات
        file_in  = $fopen("input_data.dat", "r");
        file_out = $fopen("verilog_output.dat", "w");

        if (file_in == 0) begin
            $display("❌ Error: Failed to open input_data.dat.");
            $stop;
        end

        // 3. Reset Sequence
        $display("🔄 System Reset...");
        repeat(5) @(negedge clk);
        rst_n = 1;  // Blocking
        repeat(2) @(negedge clk);

        $display("🚀 Starting Data Feed...");

        // 4. Loop through file
        while (!$feof(file_in)) begin
            scan_status = $fscanf(file_in, "%h\n", captured_data);

            if (scan_status == 1) begin
                in_valid = 1;
                in_data  = captured_data;
                
                @(negedge clk);

                in_valid = 0;
                
                repeat (50) @(negedge clk);
            end
        end

        // 5. End Simulation
        in_valid = 0;
        in_data  = 0;
        
        repeat(200) @(negedge clk);

        $fclose(file_in);
        $fclose(file_out);
        $display("✅ Simulation Finished. Output saved to verilog_output.dat");
        $stop;
    end

    // -----------------------
    // Output Capture
    // -----------------------
    always @(posedge clk) begin
        if (rst_n && out_valid) begin
            $fdisplay(file_out, "%d", out_data);
        end
    end

endmodule