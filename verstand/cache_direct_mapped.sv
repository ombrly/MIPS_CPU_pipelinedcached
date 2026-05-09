`ifndef CACHE_DIRECT_MAPPED_SV
`define CACHE_DIRECT_MAPPED_SV

module cache_direct_mapped (
    input  logic        clk, reset,
    
    // CPU Interface
    input  logic [31:0] cpu_addr,
    input  logic [31:0] cpu_writedata,
    input  logic        cpu_memwrite,
    input  logic        cpu_memread,
    output logic [31:0] cpu_readdata,
    output logic        mem_stall,
    
    // Main Memory Interface
    output logic [31:0] dmem_addr,
    output logic [31:0] dmem_writedata,
    output logic        dmem_memwrite,
    output logic        dmem_memread,
    input  logic [31:0] dmem_readdata,
    input  logic        dmem_ready
);

    // ==========================================
    // CACHE MEMORY ARRAY
    // ==========================================
    // 32-bit Address Breakdown:
    // [31:6] Tag   (26 bits)
    // [5:2]  Index (4 bits = 16 cache lines)
    // [1:0]  Byte Offset (2 bits, always 00 for word alignment)
    
    logic [25:0] tags  [0:15];
    logic [31:0] data  [0:15];
    logic        valid [0:15];

    logic [3:0]  index;
    logic [25:0] tag;
    
    assign index = cpu_addr[5:2];
    assign tag   = cpu_addr[31:6];
    
    logic hit;
    assign hit = valid[index] && (tags[index] == tag);

    // ==========================================
    // CACHE CONTROLLER FSM
    // ==========================================
    typedef enum logic [1:0] {
        COMPARE,       // Check for hit/miss
        ALLOCATE,      // On Read Miss: Fetch from Main Memory
        WRITE_THROUGH  // On Write: Write directly to Main Memory
    } state_t;
    
    state_t state, next_state;

    // Sequential State & Cache Updates
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= COMPARE;
            for (int i = 0; i < 16; i++) begin
                valid[i] <= 1'b0;
            end
        end else begin
            state <= next_state;
            
            // Update cache array on an Allocate (Read Miss resolved)
            if (state == ALLOCATE && dmem_ready) begin
                valid[index] <= 1'b1;
                tags[index]  <= tag;
                data[index]  <= dmem_readdata;
            end
            
            // Write-through policy: Update cache array if we write to a cached address
            if (state == WRITE_THROUGH && dmem_ready && hit) begin
                data[index] <= cpu_writedata;
            end
        end
    end

    // Combinational Next State & Output Logic
    always_comb begin
        // Defaults
        next_state     = state;
        mem_stall      = 1'b0;
        cpu_readdata   = 32'b0;
        
        dmem_addr      = cpu_addr;
        dmem_writedata = cpu_writedata;
        dmem_memwrite  = 1'b0;
        dmem_memread   = 1'b0;

        case (state)
            COMPARE: begin
                if (cpu_memread) begin
                    if (hit) begin
                        // Cache Hit: Supply data immediately, no stall
                        cpu_readdata = data[index];
                        mem_stall    = 1'b0;
                    end else begin
                        // Cache Miss: Freeze pipeline and fetch
                        mem_stall    = 1'b1;
                        next_state   = ALLOCATE;
                    end
                end else if (cpu_memwrite) begin
                    // Write Instruction: Freeze pipeline and write to Main Mem
                    mem_stall  = 1'b1;
                    next_state = WRITE_THROUGH;
                end
            end

            ALLOCATE: begin
                // Hold pipeline frozen, request data from slow memory
                mem_stall    = 1'b1;
                dmem_memread = 1'b1;
                dmem_addr    = {tag, index, 2'b00}; // Word-aligned fetch
                
                if (dmem_ready) begin
                    // Data arrived, next cycle will return to COMPARE and hit
                    next_state = COMPARE;
                end
            end

            WRITE_THROUGH: begin
                // Hold pipeline frozen, push write data to slow memory
                mem_stall     = 1'b1;
                dmem_memwrite = 1'b1;
                dmem_addr     = cpu_addr;
                dmem_writedata= cpu_writedata;
                
                if (dmem_ready) begin
                    // Write complete, resume pipeline execution
                    next_state = COMPARE;
                    mem_stall  = 1'b0;
                end
            end
        endcase
    end

endmodule

`endif // CACHE_DIRECT_MAPPED_SV