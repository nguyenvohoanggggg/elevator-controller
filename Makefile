#  CONFIG
RTL  = rtl/*.v
TB   = testbench/*.v
TOP  = elevator_tb
WORK = work

# TARGETS
all: run

compile:
	vlib -quiet $(WORK)
	vlog $(RTL) $(TB)

run: compile
	vsim -c $(TOP) -do "run -all; quit"

wave: compile
	vsim $(TOP) -do "do scripts/wave.do; run -all"

clean:
	rm -rf $(WORK) transcript vsim.wlf
