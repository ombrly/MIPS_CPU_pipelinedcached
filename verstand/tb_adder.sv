module tb_adder();
    logic [31:0] a, b;
    logic [31:0] y;

    adder dut (.a(a), .b(b), .y(y));

    initial begin
        $monitor("Time: %0t | a: %0d, b: %0d | y: %0d", $time, a, b, y);
        a = 32'd15; b = 32'd10; #10;
        a = 32'd100; b = -32'd20; #10;
        $finish;
    end
endmodule