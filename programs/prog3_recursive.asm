# prog3_recursive.asm
# Recursive procedure (Factorial) using proper stack frames, JAL, JR, and MULT

main:
    # Initialize Stack Pointer
    addi $sp, $zero, 240    
    
    # Set argument: Compute 3!
    addi $a0, $zero, 3      
    jal factorial
    
    # Store final result in $s0 (Expected: 6)
    add $s0, $zero, $v0     

halt:
    sw $zero, 252($zero)

factorial:
    # Prologue
    addi $sp, $sp, -8
    sw $ra, 4($sp)          # Save return address
    sw $a0, 0($sp)          # Save argument n

    # Base case condition (if n == 1)
    addi $t0, $zero, 1
    beq $a0, $t0, base_case

    # Recursive step (n - 1)
    addi $a0, $a0, -1
    jal factorial

    # Restore current n from stack
    lw $a0, 0($sp)

    # LOAD-USE Hazard / execution
    # Multiply n * factorial(n-1)
    mult $a0, $v0           
    mflo $v0                # Pull result from LO register

    # Jump to Epilogue
    j end_factorial

base_case:
    addi $v0, $zero, 1      # Return 1

end_factorial:
    # Epilogue
    lw $ra, 4($sp)          # Restore return address
    addi $sp, $sp, 8        # Pop stack frame
    jr $ra                  # Return to caller