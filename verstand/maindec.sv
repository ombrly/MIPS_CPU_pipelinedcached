`ifndef MAINDEC_SV
`define MAINDEC_SV

module maindec(
    input  logic [5:0] op,
    output logic       memtoreg, memwrite,
    output logic       branch, alusrc,
    output logic       regdst, regwrite,
    output logic       jump, jal,
    output logic [1:0] aluop
);
    logic [9:0] controls;

    assign {regwrite, regdst, alusrc, branch, memwrite, memtoreg, jump, jal, aluop} = controls;

    // Combinational truth table based on MIPS ISA opcodes
    always_comb begin
        case(op)
            6'b000000: controls = 10'b1100000010; // R-TYPE (add, sub, and, or, slt, jr)
            6'b100011: controls = 10'b1010010000; // LW
            6'b101011: controls = 10'b0010100000; // SW
            6'b000100: controls = 10'b0001000001; // BEQ
            6'b001000: controls = 10'b1010000000; // ADDI
            6'b000010: controls = 10'b0000001000; // J (Jump)
            6'b000011: controls = 10'b1000001100; // JAL (Jump and Link)
            default:   controls = 10'b0000000000; // Illegal operation / NOP
        endcase
    end

endmodule

`endif // MAINDEC_SV