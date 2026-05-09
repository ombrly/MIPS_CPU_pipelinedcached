# programs/challenge_rsqrt.asm
# Hardware-Accurate Version (Bypasses missing LUI, ORI, and JR hardware)
# Hex values converted to Base-10 to support your python assembler.

main:
    # 1. Initialize 65536 multiplier in $k0 to bypass missing LUI hardware
    addi $k0, $zero, 256
    mult $k0, $k0
    mflo $k0

    # 2. $a0 = 0x3E200000 (0x3E20 = 15904)
    addi $a0, $zero, 15904
    mult $a0, $k0
    mflo $a0

    # 3. $sp = 0x00E0
    addi $sp, $zero, 224

    # 4. Call q_rsqrt
    j q_rsqrt

ret_main:
    # 5. Halt
    addi $t0, $zero, 252
    sw  $v0, 0($t0)         
    
halt:
    j halt

# ----------------------------------------------------
q_rsqrt:
    addi $sp, $sp, -16
    sw   $s0, 8($sp)
    sw   $s1, 4($sp)
    sw   $s2, 0($sp)

    # STEP 1: x2 = number * 0.5F ($t0 = 0x00800000)
    addi $t0, $zero, 128
    mult $t0, $k0
    mflo $t0
    sub  $s0, $a0, $t0       

    # STEP 2: i = 0x5f3759df - (i >> 1) 
    srl  $t1, $a0, 1         
    addi $t2, $zero, 24375      # 0x5F37
    mult $t2, $k0
    mflo $t2
    addi $t8, $zero, 23007      # 0x59DF
    add  $t2, $t2, $t8       
    sub  $s1, $t2, $t1       

    # STEP 3.1: fmul
    add  $a0, $s1, $0        
    add  $a1, $s1, $0        
    addi $k1, $zero, 1      # Set Return ID 1
    j    fmul_emulate        
ret_1:
    add  $s2, $v0, $0        

    # STEP 3.2: fmul
    add  $a0, $s0, $0        
    add  $a1, $s2, $0        
    addi $k1, $zero, 2      # Set Return ID 2
    j    fmul_emulate
ret_2:
    add  $s2, $v0, $0        

    # STEP 3.3: fsub ($a0 = 0x3FC00000)
    addi $a0, $zero, 16320      # 0x3FC0
    mult $a0, $k0
    mflo $a0
    add  $a1, $s2, $0
    j    fsub_emulate
ret_sub_1:
    add  $s2, $v0, $0        

    # STEP 3.4: fmul
    add  $a0, $s1, $0
    add  $a1, $s2, $0
    addi $k1, $zero, 3      # Set Return ID 3
    j    fmul_emulate
ret_3:

    # EPILOGUE 
    lw   $s0, 8($sp)
    lw   $s1, 4($sp)
    lw   $s2, 0($sp)
    addi $sp, $sp, 16
    j    ret_main

# ----------------------------------------------------
fmul_emulate:
    srl  $t1, $a0, 23
    addi $t9, $0, 255        
    and  $t1, $t1, $t9       
    
    srl  $t2, $a1, 23
    and  $t2, $t2, $t9       
    
    add  $t3, $t1, $t2
    addi $t3, $t3, -127      
    
    # $t0 = 0x00800000
    addi $t0, $zero, 128
    mult $t0, $k0
    mflo $t0
    
    # $t4 = 0x007FFFFF
    addi $t4, $zero, 128
    mult $t4, $k0
    mflo $t4
    addi $t4, $t4, -1
    
    and  $t5, $a0, $t4
    or   $t5, $t5, $t0       
    
    and  $t6, $a1, $t4
    or   $t6, $t6, $t0       
    
    mult $t5, $t6
    add  $0, $0, $0          
    add  $0, $0, $0          
    mfhi $t7                 
    mflo $t8                 
    
    srl  $t9, $t7, 15
    addi $t2, $0, 1
    and  $t9, $t9, $t2
    beq  $t9, $0, fmul_norm_46
    
fmul_norm_47:
    addi $t3, $t3, 1
    addi $t2, $0, 256
    mult $t7, $t2
    add  $0, $0, $0          
    add  $0, $0, $0          
    mflo $t0                 
    
    srl  $t4, $t8, 24        
    or   $t5, $t0, $t4       
    j    fmul_pack
    
fmul_norm_46:
    addi $t2, $0, 512
    mult $t7, $t2
    add  $0, $0, $0          
    add  $0, $0, $0          
    mflo $t0
    
    srl  $t4, $t8, 23
    or   $t5, $t0, $t4       

fmul_pack:
    # $t4 = 0x007FFFFF
    addi $t4, $zero, 128
    mult $t4, $k0
    mflo $t4
    addi $t4, $t4, -1
    and  $t5, $t5, $t4
    
    # $t2 = 0x00800000 
    addi $t2, $zero, 128
    mult $t2, $k0
    mflo $t2

    mult $t3, $t2
    add  $0, $0, $0          
    add  $0, $0, $0          
    mflo $t3
    
    or   $v0, $t3, $t5
    
    # Software Return Mux
    addi $t9, $zero, 1
    beq  $k1, $t9, ret_1
    addi $t9, $zero, 2
    beq  $k1, $t9, ret_2
    addi $t9, $zero, 3
    beq  $k1, $t9, ret_3

# ----------------------------------------------------
fsub_emulate:
    srl  $t1, $a0, 23
    addi $t9, $0, 255
    and  $t1, $t1, $t9       
    
    srl  $t2, $a1, 23
    and  $t2, $t2, $t9       
    
    # $t0 = 0x00800000
    addi $t0, $zero, 128
    mult $t0, $k0
    mflo $t0
    
    # $t4 = 0x007FFFFF
    addi $t4, $zero, 128
    mult $t4, $k0
    mflo $t4
    addi $t4, $t4, -1
    
    and  $t5, $a0, $t4
    or   $t5, $t5, $t0       
    
    and  $t6, $a1, $t4
    or   $t6, $t6, $t0       
    
    sub  $t7, $t1, $t2       

align_loop:
    beq  $t7, $0, align_done
    srl  $t6, $t6, 1         
    addi $t7, $t7, -1
    j    align_loop
align_done:
    
    sub  $t5, $t5, $t6       
    add  $t3, $t1, $0        
    
    beq  $t5, $0, fsub_zero  
    
fsub_norm_loop:
    # $t8 = 0x00800000
    addi $t8, $zero, 128
    mult $t8, $k0
    mflo $t8

    and  $t9, $t5, $t8       
    
    beq  $t9, $0, fsub_norm_continue
    j    fsub_pack
fsub_norm_continue:
    
    add  $t5, $t5, $t5
    addi $t3, $t3, -1        
    j    fsub_norm_loop
    
fsub_pack:
    # $t4 = 0x007FFFFF
    addi $t4, $zero, 128
    mult $t4, $k0
    mflo $t4
    addi $t4, $t4, -1

    and  $t5, $t5, $t4

    # $t2 = 0x00800000
    addi $t2, $zero, 128
    mult $t2, $k0
    mflo $t2

    mult $t3, $t2
    add  $0, $0, $0          
    add  $0, $0, $0          
    mflo $t3
    
    or   $v0, $t3, $t5
    j    ret_sub_1
    
fsub_zero:
    add  $v0, $0, $0
    j    ret_sub_1