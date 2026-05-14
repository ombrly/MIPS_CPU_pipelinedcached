module tb_alu();
    logic        clk;
    logic [31:0] a, b, result;
    logic [4:0]  shamt;
    logic [3:0]  alucontrol;
    logic        zero;

    alu dut (.*);

    always #5 clk = ~clk; // 10 time-unit period

    initial begin
        $monitor("Time: %0t | alucontrol: %b | a: %0d, b: %0d | result: %0d, zero: %b", 
                 $time, alucontrol, a, b, result, zero);
        clk = 0; a = 32'd20; b = 32'd15; shamt = 5'd0;
        
        alucontrol = 4'b0010; // ADD
        #10;
        alucontrol = 4'b0110; // SUB
        #10;
        alucontrol = 4'b0111; // SLT (Set on Less Than)
        #10;
        $finish;
    end
endmodule