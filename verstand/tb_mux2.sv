module tb_mux2();
    logic [31:0] a, b, y;
    logic        sel;

    mux2 #(32) dut (.*);

    initial begin
        $monitor("Time: %0t | sel: %b | a: %0h, b: %0h | y: %0h", $time, sel, a, b, y);
        a = 32'hAAAAAAAA; b = 32'hBBBBBBBB; 
        sel = 0; #10;
        sel = 1; #10;
        $finish;
    end
endmodule