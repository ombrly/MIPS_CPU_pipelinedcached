`ifndef ALUDEC_SV
`define ALUDEC_SV

module aludec (
    input  logic [5:0] funct,
    input  logic [1:0] aluop,
    output logic [3:0] alucontrol
);
    always_comb begin
        case(aluop) 
            2'b00: alucontrol = 4'b0010; // add (lw/sw/addi)
            2'b01: alucontrol = 4'b0110; // sub (beq)
            2'b10: case(funct)           // R-type instructions
                6'b100000: alucontrol = 4'b0010; // ADD
                6'b100010: alucontrol = 4'b0110; // SUB
                6'b100100: alucontrol = 4'b0000; // AND
                6'b100101: alucontrol = 4'b0001; // OR
                6'b101010: alucontrol = 4'b0111; // SLT 
                6'b100111: alucontrol = 4'b1100; // NOR
                6'b000010: alucontrol = 4'b0011; // SRL
                6'b011000: alucontrol = 4'b1010; // MULT
                6'b011010: alucontrol = 4'b1011; // DIV
                6'b010000: alucontrol = 4'b1000; // MFHI
                6'b010010: alucontrol = 4'b1001; // MFLO
                default:   alucontrol = 4'bxxxx;
            endcase
            default: alucontrol = 4'bxxxx;
        endcase
    end
endmodule

`endif // ALUDEC_SV