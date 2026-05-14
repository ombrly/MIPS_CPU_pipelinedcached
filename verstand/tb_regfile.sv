module tb_regfile();
    logic        clk, we3;
    logic [4:0]  ra1, ra2, wa3;
    logic [31:0] wd3, rd1, rd2;

    regfile dut (.*);

    always #5 clk = ~clk;

    initial begin
        $monitor("Time: %0t | we3: %b, wa3: %0d, wd3: %0d | ra1: %0d -> rd1: %0d", 
                 $time, we3, wa3, wd3, ra1, rd1);
        clk = 0; we3 = 0;
        
        // Write to Register 5
        #5; we3 = 1; wa3 = 5'd5; wd3 = 32'd100; #10;
        
        // Write to Register 0 (should stay 0)
        we3 = 1; wa3 = 5'd0; wd3 = 32'd999; #10;
        
        // Read back
        we3 = 0; ra1 = 5'd5; ra2 = 5'd0; #10;
        
        $finish;
    end
endmodule