module aludec (
    input  logic [5:0] funct,
    input  logic [1:0] aluop,
    output logic [3:0] alucontrol
);
    always_comb begin
        case(aluop) 
            2'b00: alucontrol = 4'b0010; // add (for memory ops like lw/sw) for I-type
            2'b01: alucontrol = 4'b0110; // sub (for branches like beq) for I-type
            2'b10: case(funct)           // R-type instructions
                6'b100000: alucontrol = 4'b0010; // ADD
                6'b100010: alucontrol = 4'b0110; // SUB
                6'b100100: alucontrol = 4'b0000; // AND
                6'b100101: alucontrol = 4'b0001; // OR
                6'b101010: alucontrol = 4'b0111; // SLT 
                6'b100111: alucontrol = 4'b1100; // NOR
                6'b010010: alucontrol = 4'b1010; // MULT
                6'b011010: alucontrol = 4'b1011; // DIV
                6'b010000: alucontrol = 4'b1001; // mfhi
                6'b010010: alucontrol = 4'b1000; // mflo (Note: commented out to fix duplicate case conflict with MULT)
                6'b000010: alucontrol = 4'b1001; // NEW: SRL
                
                default: alucontrol = 4'bxxxx;
                6'b100000: alucontrol = 4'b0010; // ADD
                6'b100010: alucontrol = 4'b0110; // SUB
                6'b100100: alucontrol = 4'b0000; // AND
                6'b100101: alucontrol = 4'b0001; // OR
                6'b101010: alucontrol = 4'b0111; // SLT 
                6'b100111: alucontrol = 4'b1100; // NOR
                6'b000010: alucontrol = 4'b0011; // SRL
                
                // FIXED: Standard MIPS Multiplier/Divider codes
                6'b011000: alucontrol = 4'b1010; // MULT (funct changed from 010010 to 011000)
                6'b011010: alucontrol = 4'b1011; // DIV  (funct remains 011010)
                
                // FIXED: Standard MIPS HiLo extraction codes aligned with alu.sv
                6'b010000: alucontrol = 4'b1000; // MFHI (alu.sv expects 1000 for MFHI)
                6'b010010: alucontrol = 4'b1001; // MFLO (alu.sv expects 1001 for MFLO)
                
                default: alucontrol = 4'bxxxx;
            endcase
            default: alucontrol = 4'bxxxx; // Unknown
        endcase
    end
endmodule