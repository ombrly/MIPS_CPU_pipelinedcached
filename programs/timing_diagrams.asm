# programs/timing_diagrams.asm

main:
    # Initial setup NOPs to let the pipeline fill
    add $0, $0, $0
    add $0, $0, $0

# ====================================================
# CASE 1: R-Type Instructions
# ====================================================
case_r_type:
    # Load basic values using I-type first so we have data
    addi $t0, $0, 10      # $t0 = 10
    addi $t1, $0, 5       # $t1 = 5
    
    # 1. ACTUAL R-TYPE INSTRUCTION FOR DIAGRAM
    # Take your screenshot around this 'add' instruction
    add  $t2, $t0, $t1    # $t2 = 15
    
    # Extra R-types to show ALU versatility
    sub  $t3, $t0, $t1    # $t3 = 5
    and  $t4, $t0, $t1    # Bitwise AND
    or   $t5, $t0, $t1    # Bitwise OR
    slt  $t6, $t1, $t0    # Set on less than (5 < 10) -> $t6 = 1
    srl  $t7, $t0, 1      # Shift right logical (10 >> 1) -> $t7 = 5

    # NOPs to flush the pipeline and create visual space
    add $0, $0, $0
    add $0, $0, $0
    add $0, $0, $0

# ====================================================
# CASE 2: I-Type Instructions (Memory & Branching)
# ====================================================
case_i_type:
    # Load address 160 using ADDI (LUI/ORI not in maindec)
    addi $s0, $0, 160     
    addi $s1, $0, 42      # Data to store
    
    # 2. ACTUAL I-TYPE INSTRUCTIONS FOR DIAGRAM
    sw   $s1, 0($s0)      # Store Word: Write 42 to address 160
    lw   $s2, 0($s0)      # Load Word: Read 42 back into $s2
    
    # Branch I-Type (will branch successfully)
    beq  $s1, $s2, case_j_type
    
    # This instruction should get FLUSHED in the pipeline
    add  $s3, $0, $0      

    # NOPs to separate
    add $0, $0, $0
    add $0, $0, $0

# ====================================================
# CASE 3: J-Type Instructions
# ====================================================
case_j_type:
    # 3. ACTUAL J-TYPE INSTRUCTION FOR DIAGRAM
    j    skip_ahead
    
    # This instruction will be skipped entirely
    addi $v0, $0, 99

skip_ahead:
    # NOPs to create visual space before halting
    add $0, $0, $0
    add $0, $0, $0

# ====================================================
# SYSTEM HALT
# ====================================================
halt_sim:
    # Load address 252 directly using ADDI 
    addi $t0, $0, 252
    sw   $0, 0($t0)       # Write to 0xFC (252) to trigger tb $finish
    
halt:
    j    halt