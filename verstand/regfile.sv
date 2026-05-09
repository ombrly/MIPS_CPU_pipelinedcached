module regfile(
    input  logic        clk, 
    input  logic        we3, 
    input  logic [4:0]  ra1, ra2, wa3, 
    input  logic [31:0] wd3, 
    output logic [31:0] rd1, rd2 
);

    logic [31:0] rf[31:0]; // 32 registers each with 32 bits

    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1) rf[i] = 0; // initialize all datato 0.
    end

    always_ff @(negedge clk) begin //during negative edge
        if (we3) rf[wa3] <= wd3; // if write enable then write data into the register with address wa3
    end

    assign rd1 = (ra1 != 0) ? rf[ra1] : 0; // continuous: read data at address if address not empty
    assign rd2 = (ra2 != 0) ? rf[ra2] : 0;

endmodule