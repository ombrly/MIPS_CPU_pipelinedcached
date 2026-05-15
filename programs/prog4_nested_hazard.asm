# prog4_nested_hazard.asm
# Nested procedure demonstrating proper stack usage, JAL/JR, and a Load-Use Data Hazard

main:
    # Initialize stack pointer (using $sp natively)
    addi $sp, $zero, 200
    addi $s0, $zero, 10
    
    jal outer_proc
    
halt:
    sw $zero, 252($zero)
    
outer_proc:
    # Prologue: Save return address to the stack
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Call inner procedure
    jal inner_proc
    
    # Epilogue: Restore return address from the stack
    lw $ra, 0($sp)
    
    # LOAD-USE HAZARD: 
    # Attempting to jump to $ra immediately after loading it from memory!
    # Forces Pipeline inside hazard.sv to STALL natively for 1 clock cycle.
    addi $sp, $sp, 4
    jr $ra
    
inner_proc:
    add $s0, $s0, $s0
    jr $ra