module tb_maindec();
    logic [5:0] op;
    logic       memtoreg, memwrite, branch, alusrc;
    logic       regdst, regwrite, jump;
    logic [1:0] aluop;

    maindec dut (.*);

    initial begin
        $monitor("Time: %0t | op: %b | regw:%b, memw:%b, branch:%b, aluop:%b", 
                 $time, op, regwrite, memwrite, branch, aluop);
        
        op = 6'b000000; #10; // R-Type
        op = 6'b100011; #10; // LW
        op = 6'b101011; #10; // SW
        op = 6'b000100; #10; // BEQ
        $finish;
    end
endmodule
