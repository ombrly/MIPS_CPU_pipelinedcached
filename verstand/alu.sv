module alu(
    input  logic        clk,          
    input  logic [31:0] a, b,
    input  logic [4:0]  shamt,        
    input  logic [3:0]  alucontrol,   
    output logic [31:0] result,  
    output logic        zero
);
    logic [63:0] HiLo;
    logic [31:0] condinvb, sum;

    // Invert b for subtraction, adding alucontrol[2] completes 2's complement
    assign condinvb = (alucontrol[2]) ? ~b : b; 
    assign sum = a + condinvb + alucontrol[2];
    
    // Set the zero flag if the result is entirely 0s
    assign zero = (result == 32'b0);
    logic [31:0] slt_res;
    logic [31:0] hi_res;
    logic [31:0] lo_res;
    
    assign slt_res = {31'b0, sum[31]};
    assign hi_res  = HiLo[63:32];
    assign lo_res  = HiLo[31:0];
    
    always_comb begin 
        case (alucontrol)
            4'b0000: result = a & b;          // AND
            4'b0001: result = a | b;          // OR
            4'b0010: result = sum;            // ADD
            4'b0011: result = b >> shamt;     // SRL
            4'b0110: result = sum;            // SUB
            4'b0111: result = slt_res;        // SLT
            4'b1100: result = ~(a | b);       // NOR
            4'b1000: result = hi_res;         // MFHI
            4'b1001: result = lo_res;         // MFLO
            default: result = 32'bx;
        endcase
    end

    always_ff @(posedge clk) begin
        if (alucontrol == 4'b1010) begin
            HiLo <= a * b;
        end
        if (alucontrol == 4'b1011) begin 
            HiLo <= { (a % b), (a / b) };
        end
    end
endmodule 