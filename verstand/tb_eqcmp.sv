module tb_eqcmp();
    logic [31:0] a, b;
    logic        eq;

    eqcmp dut (.*);

    initial begin
        $monitor("Time: %0t | a: %0d, b: %0d | eq: %b", $time, a, b, eq);
        a = 32'd42; b = 32'd42; #10;
        a = 32'd42; b = 32'd10; #10;
        $finish;
    end
endmodule