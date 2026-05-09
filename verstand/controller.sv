`ifndef CONTROLLER_SV
`define CONTROLLER_SV

`include "maindec.sv"
`include "aludec.sv"

module controller(
    input  logic [5:0] opD, functD,
    output logic       memtoregD, memwriteD,
    output logic       alusrcD, regdstD, regwriteD,
    output logic       jumpD, branchD,
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
        .aluop(aluopD)
    );

    // ALU Decoder
    aludec ad(
        .funct(functD),
        .aluop(aluopD),
        .alucontrol(alucontrolD)
    );

endmodule

`endif // CONTROLLER_SV