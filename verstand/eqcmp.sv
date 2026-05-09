`ifndef EQCMP_SV
`define EQCMP_SV

module eqcmp (
    input  logic [31:0] a, b,
    output logic        eq
);
    assign eq = (a == b);
endmodule

`endif // EQCMP_SV