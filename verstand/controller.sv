`ifndef CONTROLLER_SV
`define CONTROLLER_SV

`include "maindec.sv"
`include "aludec.sv"

module controller(
    input  logic [5:0] opD, functD,
    output logic       memtoregD, memwriteD,
    output logic       alusrcD, regdstD, regwriteD,
    output logic       jumpD, branchD, jalD, jrD,
    output logic [3:0] alucontrolD
);
    logic [1:0] aluopD;

    // Main Decoder
    maindec md(
        .op(opD),
        .memtoreg(memtoregD),
        .memwrite(memwriteD),
        .branch(branchD),
        .alusrc(alusrcD),
        .regdst(regdstD),
        .regwrite(regwriteD),
        .jump(jumpD),
        .jal(jalD),
        .aluop(aluopD)
    );

    // ALU Decoder
    aludec ad(
        .funct(functD),
        .aluop(aluopD),
        .alucontrol(alucontrolD)
    );
    // just for jr
    assign jrD = (opD == 6'b000000) && (functD == 6'b001000);

endmodule

`endif // CONTROLLER_SV