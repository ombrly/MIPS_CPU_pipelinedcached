`ifndef DMEM_SV
`define DMEM_SV

module dmem(
    input  logic        clk, reset,
    input  logic        memread, memwrite,
    input  logic [31:0] addr,
    input  logic [31:0] writedata,
    output logic [31:0] readdata,
    output logic        dmem_ready
);

    logic [31:0] RAM[0:255];
    logic [3:0]  latency_counter; 

    // The Cache Controller/CPU will only sample this when dmem_ready is high.
    assign readdata = RAM[addr[9:2]];

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            latency_counter <= 4'd10; // 10 cycle memory wall latency
            dmem_ready      <= 1'b0;
            // Initialize memory arrays to zero
            for (int i=0; i<256; i++) begin
                RAM[i] <= 32'b0;
            end
        end else begin
            // If the CPU/Cache requests a memory operation and we haven't finished yet
            if ((memread || memwrite) && !dmem_ready) begin
                if (latency_counter > 4'd1) begin
                    // Count down the latency penalty
                    latency_counter <= latency_counter - 4'd1;
                    dmem_ready      <= 1'b0;
                end else begin
                    // Latency finished. Data is ready.
                    dmem_ready      <= 1'b1; 
                    latency_counter <= 4'd10; // Reset the counter for the next access
                    if (memwrite) begin
                        RAM[addr[9:2]] <= writedata;
                    end
                end
            end else begin
                dmem_ready      <= 1'b0;
                latency_counter <= 4'd10;
            end
        end
    end

endmodule

`endif // DMEM_SV