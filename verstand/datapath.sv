`ifndef DATAPATH_SV
`define DATAPATH_SV

`include "regfile.sv"
`include "alu.sv"
`include "adder.sv"
`include "sl2.sv"
`include "mux2.sv"
`include "mux3.sv"
`include "signext.sv"
`include "eqcmp.sv"

module datapath(
    input  logic        clk, reset,
    output logic [31:0] pcF,
    input  logic [31:0] instrF,
    output logic [31:0] aluoutM, writedataM,
    input  logic [31:0] readdataM,

    // Control signals from Decode
    input  logic        memtoregD, memwriteD,
    input  logic        alusrcD, regdstD, regwriteD,
    input  logic        jumpD, branchD,
    input  logic [3:0]  alucontrolD,
    output logic [31:0] instrD,

    // Hazard signals
    input  logic        stallF, stallD, stallE, stallM, stallW, flushD, flushE,
    input  logic        Exception_Flag,
    input  logic        forwardaD, forwardbD,
    input  logic [1:0]  forwardaE, forwardbE,

    // Hazard tracking outputs
    output logic [4:0]  rsD, rtD, rsE, rtE,
    output logic [4:0]  writeregE, writeregM, writeregW,
    output logic        regwriteE, regwriteM, regwriteW,
    output logic        memtoregE, memtoregM,
    output logic        memwriteM_out
);
    // FETCH STAGE (IF)
    logic [31:0] pcnextFD, pcnextbrFD, pcplus4F, pcbranchD;
    logic pcsrcD;
    logic [31:0] pcplus4D;
    logic [31:0] pcjumpFD;

    //jump vs branch
    mux2 #(32) pcbrmux(pcplus4F, pcbranchD, pcsrcD, pcnextbrFD);
    assign pcjumpFD = {pcplus4D[31:28], instrD[25:0], 2'b00};

    always_comb begin
        if (Exception_Flag) pcnextFD = 32'h8000_0180; // Hardware exception vector
        else if (jumpD)     pcnextFD = pcjumpFD;
        else                pcnextFD = pcnextbrFD;
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset)       pcF <= 32'b0;
        else if (~stallF) pcF <= pcnextFD; // Freeze PC if memory stall or data hazard
    end
    
    assign pcplus4F = pcF + 32'b100;

    // IF/ID PIPELINE REGISTER
    always_ff @(posedge clk or posedge reset) begin
        if (reset || flushD) begin // Flush on exceptions
            instrD   <= 32'b0;
            pcplus4D <= 32'b0;
        end else if (~stallD) begin
            instrD   <= (pcsrcD || jumpD) ? 32'b0 : instrF; // Flush dynamically on branch/jump
            pcplus4D <= pcplus4F;
        end
    end

    // DECODE STAGE (ID)
    logic [31:0] srcaD, srcbD;
    logic [31:0] signimmD, signimmshD;
    logic [31:0] resultW;
    logic        equalD;
    logic [4:0]  rdD;
    logic [31:0] compaD, compbD;

    assign rsD = instrD[25:21];
    assign rtD = instrD[20:16];
    assign rdD = instrD[15:11];
    
    logic [4:0] shamtD;
    assign shamtD = instrD[10:6];
    
    regfile rf(clk, regwriteW, rsD, rtD, writeregW, resultW, srcaD, srcbD);

    // Branch eval 
    assign compaD = forwardaD ? aluoutM : srcaD;
    assign compbD = forwardbD ? aluoutM : srcbD;
    eqcmp comp(compaD, compbD, equalD);
    
    assign pcsrcD = branchD & equalD;
    assign signimmshD = signimmD << 2;
    assign pcbranchD = pcplus4D + signimmshD;
    signext se(instrD[15:0], signimmD);

    // ID/EX PIPELINE REGISTER 
    logic [31:0] srcaE, srcbE, signimmE;
    logic [4:0]  rdE;
    logic [4:0]  shamtE;
    logic memwriteE, alusrcE, regdstE;
    logic [3:0] alucontrolE;
    logic [31:0] pcplus4E;

    always_ff @(posedge clk or posedge reset) begin
        if (reset || flushE) begin // Bubble insertion
            regwriteE   <= 0;
            memtoregE   <= 0;
            memwriteE   <= 0;
            alusrcE     <= 0;
            regdstE     <= 0;
            alucontrolE <= 0;
            srcaE       <= 0;
            srcbE       <= 0;
            signimmE    <= 0;
            rsE         <= 0;
            rtE         <= 0;
            rdE         <= 0;
            shamtE      <= 0; 
            pcplus4E    <= 0;
        end else if (~stallE) begin
            regwriteE   <= regwriteD;
            memtoregE   <= memtoregD;
            memwriteE   <= memwriteD;
            alusrcE     <= alusrcD;
            regdstE     <= regdstD;
            alucontrolE <= alucontrolD;
            srcaE       <= srcaD;
            srcbE       <= srcbD;
            signimmE    <= signimmD;
            rsE         <= rsD;
            rtE         <= rtD;
            rdE         <= rdD;
            shamtE      <= shamtD;
            pcplus4E    <= pcplus4D;
        end
    end

    // EXECUTE STAGE (EX)
    logic [31:0] srca2E, srcb2E, srcb3E;
    logic [31:0] aluoutE;
    logic zeroE; 
    
    // ALU Forwarding Muxes
    mux3 #(32) forwardamux(srcaE, resultW, aluoutM, forwardaE, srca2E);
    mux3 #(32) forwardbmux(srcbE, resultW, aluoutM, forwardbE, srcb2E);
    mux2 #(32) srcbmux(srcb2E, signimmE, alusrcE, srcb3E);
    
    alu alu(clk, srca2E, srcb3E, shamtE, alucontrolE, aluoutE, zeroE);
    mux2 #(5) wrmux(rtE, rdE, regdstE, writeregE);
    
    // Exception tracking
    logic [31:0] EPC;
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            EPC <= 32'b0;
        end else if (Exception_Flag) begin
            EPC <= pcplus4D - 32'd4; // Save the address of the interrupted instruction
        end
    end

    // EX/MEM PIPELINE REGISTER 
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            regwriteM <= 0;
            memtoregM <= 0;
            memwriteM_out <= 0;
            aluoutM   <= 0;
            writedataM<= 0;
            writeregM <= 0;
        end else if (~stallM) begin
            regwriteM <= regwriteE;
            memtoregM <= memtoregE;
            memwriteM_out <= memwriteE;
            aluoutM   <= aluoutE;
            writedataM<= srcb2E; // Forwarded write data for store instructions
            writeregM <= writeregE;
        end
    end

    // MEMORY STAGE (MEM)
    // Note: Actual memory interaction occurs in computer.sv via dmem.sv/caches.

    // MEM/WB PIPELINE R's
    logic memtoregW;
    logic [31:0] readdataW, aluoutW;
    
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            regwriteW <= 0;
            memtoregW <= 0;
            readdataW <= 0;
            aluoutW   <= 0;
            writeregW <= 0;
        end else if (~stallW) begin
            regwriteW <= regwriteM;
            memtoregW <= memtoregM;
            readdataW <= readdataM; // Data retrieved from cache/memory
            aluoutW   <= aluoutM;
            writeregW <= writeregM;
        end
    end

    // WRITEBACK STAGE (WB)
    mux2 #(32) resmux(aluoutW, readdataW, memtoregW, resultW);

endmodule
`endif // DATAPATH_SV