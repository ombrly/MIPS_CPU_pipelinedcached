module tb_sl2();
    logic [31:0] a, y;

    sl2 dut (.*);

    initial begin
        $monitor("Time: %0t | a: %h | y: %h", $time, a, y);
        a = 32'h00000001; #10;
        a = 32'h00000004; #10;
        a = 32'hFFFFFFFF; #10;
        $finish;
    end
endmodule