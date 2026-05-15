# MIPS Pipelined CPU with Cache

## Overall Design Explanation

The CPU is a pipelined implementation based on MIPS. Unlike a single-cycle CPU, this processor divides instruction execution into multiple stages so that multiple instructions can be active at the same time.

The five main pipeline stages are:

1. IF: Instruction Fetch
2. ID: Instruction Decode
3. EX: Execute
4. MEM: Memory Access
5. WB: Write Back

The main decoder reads the opcode in the instruction and generates the high-level control signals. The ALU decoder reads the `funct` field for R-type instructions and determines the exact ALU operation.

This CPU also includes hazard handling and direct-mapped cache support. The hazard unit is responsible for stalls, flushes, and forwarding. The cache module is used between the CPU and data memory to support faster memory access on hits and pipeline stalls on misses.

## Supported Instructions

Based on the main decoder and ALU decoder, the supported instructions are:

### R-Type Instructions

- add
- sub
- and
- or
- nor
- slt
- srl
- mult
- div
- mfhi
- mflo

### I-Type Instructions

- addi
- lw
- sw
- beq

### J-Type Instructions

- j

### Overall Design Diagrams

![Overall CPU Diagram](<https://github.com/user-attachments/assets/74ddf8dc-ad3b-4c90-a82a-56321549afd0" />)

## ISA Design

ALU operand size: 32 bits

Address bus size: 32 bits

Addressability: Byte-addressable

Register file size: 32 registers x 32 bits

Opcode size: 6 bits

Funct size: 6 bits

Shamt size: 5 bits

Instruction size: 32 bits

PC increment: 4 bytes

Immediate size: 16 bits, sign-extended to 32 bits for operations

### R-Type Instruction Format

| op     | rs     | rt     | rd     | shamt  | funct  |
| ------ | ------ | ------ | ------ | ------ | ------ |
| 6 bits | 5 bits | 5 bits | 5 bits | 5 bits | 6 bits |

### I-Type Instruction Format
| op     | rs     | rt     | immediate/address |
| ------ | ------ | ------ | ----------------- |
| 6 bits | 5 bits | 5 bits | 16 bits           |

### J-Type Instruction Format
| op     | address |
| ------ | ------- |
| 6 bits | 26 bits |

## Memory Design and Implementation

### Instruction Memory: imem

- Instruction memory stores the 32-bit machine code instructions generated from the assembly programs.
- The program counter determines which instruction is read.
- Each instruction is word-aligned, so the PC normally increments by 4.

### Data Memory: dmem

- Data memory stores 32-bit values used by load and store instructions.
- For lw, the CPU reads from data memory.
- For sw, the CPU writes to data memory.

### Cache Memory: cache_direct_mapped

The CPU includes a direct-mapped cache between the processor and data memory.

The cache uses the following address breakdown:
| Address Bits | Purpose     |
| ------------ | ----------- |
| `[31:6]`     | Tag         |
| `[5:2]`      | Index       |
| `[1:0]`      | Byte offset |

The cache has 16 lines because the index is 4 bits. On a cache hit, the data is returned without stalling the pipeline.
On a cache miss, the cache asserts mem_stall, which freezes the pipeline while data is fetched from main memory. The cache uses a write-through policy for store instructions.

### Memory Layout
Instruction memory and data memory are separate.
- Instruction memory stores assembled machine code.
- Data memory stores values used by lw and sw.

The testbench halts the simulation when the CPU writes to address:
``` 252 decimal = 0x000000FC ```

### Program Load into Processor

Assembly programs are stored in the programs/ folder. The assembler script converts an assembly file into an executable machine-code file. The Makefile assembles a selected program, compiles the CPU simulation, and runs the testbench.

Default program:
``` prog1_simple_hazard.asm ```
To select a different program:
``` make ASM=program_name_without_extension ```

## Process Design and Implementation

### Control Signals

### RegDst
This controls which register is written.
| RegDst | Effect                       |
| ------ | ---------------------------- |
| 0      | Destination register is `rt` |
| 1      | Destination register is `rd` |

### Jump
This controls jump behavior.
| Jump | Effect                                   |
| ---- | ---------------------------------------- |
| 0    | PC uses normal sequential or branch path |
| 1    | PC jumps to jump address                 |
Jump address: ```{PCPlus4[31:28], instr[25:0], 2'b00}```

### Branch 
This was used for beq
| Branch | Equal | Effect                        |
| ------ | ----- | ----------------------------- |
| 0      | x     | PC continues normally         |
| 1      | 0     | PC continues normally         |
| 1      | 1     | PC branches to target address |
Branch Address: ```PCPlus4 + (sign-extended immediate << 2)```

### MemRead
The cache/memory system uses this signal.
| MemRead | Effect                      |
| ------- | --------------------------- |
| 0       | No memory read              |
| 1       | Read data from memory/cache |

### MemWrite
| MemWrite | Effect                     |
| -------- | -------------------------- |
| 0        | No memory write            |
| 1        | Write data to memory/cache |

### Mem     
ontrols 
