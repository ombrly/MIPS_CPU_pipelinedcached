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

### Instructions to Run Demo
```
cd MIPS_CPU_pipelinedcached/verstand
make asm
make compile
make run
```

 Program Output:
 ```
--- Running simulation ---
vvp cpu_sim +PROG=../programs/prog1_simple_hazard.exe
WARNING: ./imem.sv:15: $readmemh(../programs/prog1_simple_hazard.exe): Not enough words in the file for the requested range [0:255].
VCD info: dumpfile tb_computer.vcd opened for output.
--------------------------------------------------
Simulation Halted by Software.
CPU wrote value [0] to universal halt address 252 (0xFC).
--------------------------------------------------
tb_computer.sv:64: $finish called at 2100 (100ps)
```

### Overall Design Diagrams

![Overall CPU Diagram](https://github.com/ombrly/MIPS_CPU_pipelinedcached/blob/main/overalldiagram.jpg?raw=true)


![R-Type Timing Diagram]()
![I-Type Timing Diagram]()
![J-Type Timing Diagram]()


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
-jr

### I-Type Instructions

- addi
- lw
- sw
- beq

### J-Type Instructions

- j
- jal



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

### ALU Control Encoding
The ALU control signal is named alucontrol. It is 4 bits wide. For non-R-type instructions, aluop directly determines the ALU operation. For R-type instructions, aluop = 2'b10, and the ALU decoder uses the funct field to select the operation.
| `aluop` / `funct` | `alucontrol` | Operation                  |
| ----------------- | -----------: | -------------------------- |
| `aluop = 00`      |       `0010` | Add for `lw`, `sw`, `addi` |
| `aluop = 01`      |       `0110` | Subtract for `beq`         |
| `funct = 100000`  |       `0010` | ADD                        |
| `funct = 100010`  |       `0110` | SUB                        |
| `funct = 100100`  |       `0000` | AND                        |
| `funct = 100101`  |       `0001` | OR                         |
| `funct = 101010`  |       `0111` | SLT                        |
| `funct = 100111`  |       `1100` | NOR                        |
| `funct = 000010`  |       `0011` | SRL                        |
| `funct = 011000`  |       `1010` | MULT                       |
| `funct = 011010`  |       `1011` | DIV                        |
| `funct = 010000`  |       `1000` | MFHI                       |
| `funct = 010010`  |       `1001` | MFLO                       |

### Register and Memory Behavior

The register file contains 32 registers, each 32 bits wide. The source register fields are decoded as:
``` rsD = instrD[25:21]
rtD = instrD[20:16]
rdD = instrD[15:11]
```

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

# Process Design and Implementation

##Pipeline Stage Breakdown

### Instruction Fetch Stage

The IF stage contains the PC, Instruction Memory (imem), and next-PC selection logic.

The PC provides the instruction address. In the top-level computer module, the instruction memory receives pc[9:2] and outputs instr, which becomes instrF in the CPU. The instruction side is not cached in this design; it uses imem directly.

Main IF-stage signals:
```
pcF
instrF
pcplus4F
stallF
```

The next-PC logic chooses the next PC based on this priority:
```
1. Exception_Flag → 0x80000180
2. jrD → compaD
3. jumpD → jump target
4. pcsrcD = branchD & equalD → branch target
5. PC + 4
```
This matches the datapath logic, where Exception_Flag, jrD, jumpD, and branch selection determine pcnextFD.

## Instruction Decode Stage

The ID stage contains the Register File, Main Decoder, Sign Extend, branch target calculation, jump target logic, and equality comparison logic.

The instruction fields are decoded as:
```
rsD = instrD[25:21]
rtD = instrD[20:16]
rdD = instrD[15:11]
```

The register file reads srcaD and srcbD, which correspond to the register values used by later stages. The writeback value is called resultW in the GitHub code. It returns from the WB stage into the register file as the write data.

Main ID-stage signals:
```
instrD
rsD
rtD
rdD
srcaD / readData1D
srcbD / readData2D
signimmD / immExtD
compaD
compbD
equalD / eqD
branchD
jumpD
jalD
jrD
```
Decode-stage forwarding is used for branch and jr comparisons. The comparator inputs are chosen as:
```
compaD = forwardaD ? aluoutM : srcaD
compbD = forwardbD ? aluoutM : srcbD
```
This means the comparator can use aluoutM instead of stale register-file values when the newest value is in the MEM stage.

### Execute Stage

The EX stage contains the forwarding muxes, ALUSrc mux, RegDst mux, and ALU.

The ID/EX pipeline register carries source register values, immediate values, register numbers, and control signals into EX. Important EX-stage signals include:
```
srcaE / readData1E
srcbE / readData2E
signimmE / immExtE
rsE
rtE
rdE
regdstE
alusrcE
alucontrolE
regwriteE
memtoregE
memwriteE
writeregE
aluoutE
```
The EX forwarding muxes choose among:
```
0: srcaE / srcbE
1: resultW
2: aluoutM
```
The forwarding controls are:
```
forwardaE[1:0]
forwardbE[1:0]
```
The ALU output is called aluoutE. The selected destination register is called writeregE. For normal instructions, writeregE comes from the RegDst mux. For jal, it is overridden to register $ra, which is register 31.

### Memory Stage

The MEM stage contains the EX/MEM pipeline register and the data memory/cache system.

The EX/MEM pipeline register carries:
```
aluoutM
writedataM
writeregM
regwriteM
memtoregM
memwriteM
```
The data cache/dmem receives the address and write data:
```
aluoutM → dataadr / addrM
writedataM → write data
```
In computer.sv, aluoutM from the CPU is connected to dataadr, and writedataM is connected to writedata. The direct-mapped cache receives these as CPU-side address and write data.

The actual memory read control is derived from memtoregM:
```
memreadM = memtoregM
```
The memory/cache system outputs:
```
readdataM
mem_stall
```
mem_stall comes from the data cache when caching is enabled, or from direct dmem_ready behavior when caching is disabled.

### Write Back Stage

The WB stage contains the MEM/WB pipeline register and the Result MUX.

The MEM/WB register carries:
```
aluoutW
readdataW
pcplus4W
writeregW
regwriteW
memtoregW
jalW
```
The Result MUX chooses the value written back to the Register File:
```
0: aluoutW
1: readdataW
2: pcplus4W for jal
```

In the GitHub code, the final writeback value is named:
```
resultW
```

The code first chooses between aluoutW and readdataW using memtoregW, then overrides the result with pcplus4W when jalW is active, so the writeback path is:

```Result MUX → resultW → Register File write data```

The destination register and write enable also return to the register file:
```
writeregW → Register File write register
regwriteW → Register File write enable
```

## Hazard Detection and Forwarding

The hazard module detects pipeline hazards, controls stalls and flushes, and generates forwarding controls.

Hazard inputs include:
```
rsD, rtD, rsE, rtE
writeregE, writeregM, writeregW
regwriteE, regwriteM, regwriteW
memtoregE, memtoregM
branchD
jrD
intr
mem_stall
```
Hazard outputs include:
```
forwardaD
forwardbD
forwardaE[1:0]
forwardbE[1:0]
stallF
stallD
stallE
stallM
stallW
flushD
flushE
Exception_Flag
```
The hazard unit forwards data to the EX-stage ALU inputs using forwardaE and forwardbE. It also forwards data to the decode-stage branch comparator using forwardaD and forwardbD. The GitHub hazard logic sets forwardaE and forwardbE based on matches between rsE/rtE and later-stage destination registers, and sets forwardaD/forwardbD for decode-stage branch and JR comparisons.

The hazard unit also handles stalls and flushes. It generates load-use stalls, branch/JR stalls, memory stalls, and interrupt exception flags. It outputs only flushD and flushE; there is no flushM signal in the GitHub hazard module.

## Memory Design and Implementation

### Instruction Memory

The instruction memory is implemented as imem. It receives:
```
addr = pc[9:2]
```
and outputs:
```
instr
```

### Data Cache and Data Memory

The data side uses a direct-mapped cache module named cache_direct_mapped, connected to dmem.

The CPU provides:
```
aluoutM / dataadr
writedataM / writedata
memwriteM
memreadM
```
The cache/memory system returns:
```
readdataM
mem_stall
```
When cache_en is active, memory accesses go through the direct-mapped cache. When cache_en is inactive, the CPU reads directly from dmem. The selected read data is assigned to readdata, and mem_stall is selected based on whether the cache path or direct memory path is being used.

## Control Signal Summary

### Decode-stage controls
Generated by the controller:
```
memtoregD
memwriteD
alusrcD
regdstD
regwriteD
branchD
jumpD
jalD
jrD
alucontrolD
```

##Execute-stage controls
Stored in ID/EX and used in EX:
```
memtoregE
memwriteE
alusrcE
regdstE
regwriteE
branchE
jumpE
jalE
alucontrolE
```

### Memory-stage controls
Stored in EX/MEM and used in MEM:
```
memtoregM
memwriteM
regwriteM
branchM
jumpM
jalM
```

 ### Writeback-stage controls
Stored in MEM/WB and used in WB:
```
memtoregW
regwriteW
jalW
```
## Pipeline Register Summary

### IF/ID
Stores:
```
instrD
pcplus4D
```
Controlled by:
```
stallD
flushD
```

### ID/EX
Stores:
```
srcaE / readData1E
srcbE / readData2E
signimmE / immExtE
rsE
rtE
rdE
pcplus4E
controlE
```
Controlled by:
```
stallE
flushE
```

### EX/MEM
Stores:
```
aluoutM
writedataM
writeregM
pcplus4M
controlM
```
Controlled by:
```
stallM
```

### MEM/WB
Stores:
```
aluoutW
readdataW
pcplus4W
writeregW
controlW
```
Controlled by:
```stallW```

