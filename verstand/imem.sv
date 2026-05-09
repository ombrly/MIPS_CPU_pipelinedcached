`ifndef IMEM_SV
`define IMEM_SV

module imem(
    input  logic [7:0]  addr, 
    output logic [31:0] readdata
);

    logic [31:0] RAM[0:255]; 

    initial begin
        string prog_file;
        // Dynamically read the file path passed by the Makefile's +PROG flag
        if ($value$plusargs("PROG=%s", prog_file)) begin
            $readmemh(prog_file, RAM);
        end else begin
            // Safe fallback if ran without the Makefile
            $readmemh("../programs/prog1_simple_hazard.exe", RAM);
        end
    end
    
    assign readdata = RAM[addr];

endmodule

`endif // IMEM_SV