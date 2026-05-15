# prog2_leaf_hazard.asm
# Leaf procedure triggering a Branch Hazard (Control Hazard) and using JAL/JR

main:
    addi $s0, $zero, 1
    addi $s1, $zero, 1
    
    # BEQ causes a control hazard natively since IF/ID must flush predictions
    beq $s0, $s1, call_leaf
    
    # This should be skipped/flushed dynamically!
    addi $s2, $zero, 999 
    
call_leaf:
    jal leaf_proc
    
halt:
    # End of execution (Halt via Memory-Mapped I/O)
    sw $zero, 252($zero)
    
leaf_proc:
    # Leaf procedure execution
    add $s2, $s0, $s1
    
    # Return to caller using the address saved in $ra by JAL
    jr $ra