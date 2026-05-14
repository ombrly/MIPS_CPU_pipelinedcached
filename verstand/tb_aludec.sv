module tb_aludec();
    logic [5:0] funct;
    logic [1:0] aluop;
    logic [3:0] alucontrol;

    aludec dut (.*);

    initial begin
        $monitor("Time: %0t | aluop: %b, funct: %b | alucontrol: %b", $time, aluop, funct, alucontrol);
        
        aluop = 2'b00; funct = 6'b000000; #10; // lw/sw
        aluop = 2'b01; funct = 6'b000000; #10; // beq
        aluop = 2'b10; funct = 6'b100000; #10; // R-type: ADD
        aluop = 2'b10; funct = 6'b100100; #10; // R-type: AND
        $finish;
    end
endmodule