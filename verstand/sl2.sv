`ifndef SL2_SV
`define SL2_SV

module sl2 (
    input  logic [31:0] a,
    output logic [31:0] y
);
    assign y = a << 2;
endmodule

`endif // SL2_SV