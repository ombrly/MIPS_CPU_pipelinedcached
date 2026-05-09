# Default test to run if none is specified
ASM ?= prog1_simple_hazard

# Directories
PROG_DIR = ../programs
TOOLS_DIR = ../tools

# Simulator executable name
SIM_EXEC = cpu_sim

# Top-level testbench
TB = tb_computer.sv

.PHONY: all asm compile run clean

# The default target runs everything in sequence
all: asm compile run

asm:
	@echo "--- Assembling $(ASM).asm ---"
	python3 $(TOOLS_DIR)/assembler.py $(PROG_DIR)/$(ASM).asm $(PROG_DIR)/$(ASM).exe

compile:
	@echo "\n--- Compiling CPU simulation ---"
	iverilog -g2012 -I . -o $(SIM_EXEC) $(TB)

run:
	@echo "\n--- Running simulation ---"
	vvp $(SIM_EXEC) +PROG=$(PROG_DIR)/$(ASM).exe

clean:
	@echo "--- Cleaning up generated files ---"
	rm -f $(SIM_EXEC) $(PROG_DIR)/*.exe *.vcd debug_output.txt