`timescale 1ns/100ps
`include "computer.sv"

module tb_computer;
    logic        clk;
    logic        reset;
    logic        intr;
    logic        cache_en;
    logic [31:0] writedata, dataadr;
    logic        memwrite;

    // Instantiate the top-level computer system
    computer dut (
        .clk(clk),
        .reset(reset),
        .intr(intr),
        .cache_en(cache_en),
        .writedata(writedata),
        .dataadr(dataadr),
        .memwrite(memwrite)
    );

    // Clock generation (10ns period / 100MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk; 
    end

    // Simulation stimulus and configuration
    initial begin
        // Generate waveform file for GTKWave verification
        $dumpfile("tb_computer.vcd");
        $dumpvars(0, tb_computer);

        // Initialize system inputs
        intr     = 0;
        cache_en = 1; 
        reset    = 1;
        
        // Hold reset high for a few cycles to clear pipeline registers
        #22;
        reset = 0;

        // Failsafe timeout to prevent infinite simulation loops
        #50000;
        $display("ERROR: Simulation Timed Out.");
        $finish;
    end

    // Universal Halt Condition Monitor
    // Triggered on the falling edge to ensure data and signals are stable
    always @(negedge clk) begin
        if (memwrite) begin
            if (dataadr === 32'h000000FC || dataadr === 32'd252) begin
                $display("--------------------------------------------------");
                $display("Simulation Halted by Software.");
                $display("CPU wrote value [%0d] to universal halt address 252 (0xFC).", writedata);
                $display("--------------------------------------------------");
                $finish;
            end
        end
    end

endmodule