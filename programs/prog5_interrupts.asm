# prog5_interrupts.asm
# Tests asynchronous interrupts triggering pipeline flushes and routing to the OS Handler

main:
    addi $s0, $zero, 0
loop:
    addi $s0, $s0, 1
    addi $s0, $s0, 1
    addi $s0, $s0, 1
    j loop

# OS Exception Handler
.org 0x180
handler:
    addi $k0, $zero, 999   # arbitrary math
    
    # Break out of the handler and end the simulation
    j halt

halt:
    sw $zero, 252($zero)