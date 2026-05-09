# test_srl.asm
# Verifies the newly implemented Shift Right Logical (srl) instruction

.org 0x00

# 1. Load test values
addi $t0, $zero, 32     # Load 32 into $t0

# 2. Test the SRL datapath 
srl  $t1, $t0, 3        # Shift right logical by 3 (32 >> 3 = 4)
                        # $t1 should now contain 4

# 3. Trigger Universal Halt
addi $t2, $zero, 252    # Load halt address (0xFC) into $t2
sw   $t1, 0($t2)        # Write the result (4) to address 252. 
                        # The testbench will intercept this and print 4 to the terminal.