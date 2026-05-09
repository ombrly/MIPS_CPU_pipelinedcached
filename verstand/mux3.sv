module mux3 #(parameter WIDTH = 32) (
    input logic [WIDTH-1:0] a, b, c,
    input logic [1:0] sel,
    output logic [WIDTH-1:0] y
);
    assign y = sel[1] ? c : (sel[0] ? b : a);
endmodule