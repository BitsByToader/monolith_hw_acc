######################################################################
#
# DESCRIPTION: Verilator Example: Small Makefile
#
# This calls the object directory makefile.  That allows the objects to
# be placed in the "current directory" which simplifies the Makefile.
#
# This file ONLY is placed under the Creative Commons Public Domain, for
# any use, without warranty, 2020 by Wilson Snyder.
# SPDX-License-Identifier: CC0-1.0
#
######################################################################
# Check for sanity to avoid later confusion

ifneq ($(words $(CURDIR)),1)
  $(error Unsupported: GNU Make cannot build in directories containing spaces, build elsewhere: '$(CURDIR)')
endif

######################################################################
# Set up variables

# If $VERILATOR_ROOT isn't in the environment, we assume it is part of a
# package install, and verilator is in your path. Otherwise find the
# binary relative to $VERILATOR_ROOT (such as when inside the git sources).
ifeq ($(VERILATOR_ROOT),)
  VERILATOR = verilator
  VERILATOR_COVERAGE = verilator_coverage
else
  export VERILATOR_ROOT
  VERILATOR = $(VERILATOR_ROOT)/bin/verilator
  VERILATOR_COVERAGE = $(VERILATOR_ROOT)/bin/verilator_coverage
endif

# Run on as many cores as possible
VERILATOR_FLAGS += -j 0
# Generate executable form
VERILATOR_FLAGS += -binary
# Generate makefile dependencies (not shown as complicates the Makefile)
#VERILATOR_FLAGS += -MMD
# Optimize
VERILATOR_FLAGS += -x-assign fast
# Warn abount lint issues; may not want this on less solid designs
VERILATOR_FLAGS += -Wall
# Make warnings non-fatal
VERILATOR_FLAGS += --Wno-fatal
# Make waveforms
VERILATOR_FLAGS += --trace
# Check SystemVerilog assertions
VERILATOR_FLAGS += --assert
# Generate coverage analysis
#VERILATOR_FLAGS += --coverage
# Run Verilator in debug mode
#VERILATOR_FLAGS += --debug
# Add this trace to get a backtrace in gdb
#VERILATOR_FLAGS += --gdbbt
# Enable Verilog timing
VERILATOR_FLAGS += --timing
# Set top module
VERILATOR_FLAGS += -top $(top_module)
# Set generic prefix
VERILATOR_FLAGS += -prefix Vtop

# Set top file
VERILATOR_INPUT += $(top_file)
# Input files for Verilator
VERILATOR_INPUT += -f input.vc

######################################################################
default: run

run:
	@echo
	@echo "-- Running Verilator -------"

	@echo
	@echo "-- VERILATE ----------------"
	$(VERILATOR) $(VERILATOR_FLAGS) $(VERILATOR_INPUT)

	@echo
	@echo "-- BUILD -------------------"
# To compile, we can either
# 1. Pass --build to Verilator by editing VERILATOR_FLAGS above.
# 2. Or, run the make rules Verilator does:
#	$(MAKE) -j -C obj_dir -f Vtop.mk
# 3. Or, call a submakefile where we can override the rules ourselves:
	$(MAKE) -j -C obj_dir -f ../Makefile_obj

	@echo
	@echo "-- RUN ---------------------"

	@rm -f *.mem
	@ln -s ../../rtl/constants/*.mem .
	@ln -s ../../testbench/test_vectors/*.mem .

	@rm -rf logs
	@mkdir -p logs

	obj_dir/Vtop +trace

	@echo
	@echo "-- COVERAGE ----------------"
	@rm -rf logs/annotated
	@echo "NO COVERAGE CONFIGURED"
# $(VERILATOR_COVERAGE) --annotate logs/annotated logs/coverage.dat

	@echo
	@echo "-- DONE --------------------"
	@echo "Waveforms are ready to view!"
	@echo

######################################################################
# Other targets

show-config:
	$(VERILATOR) -V

maintainer-copy::
clean mostlyclean distclean maintainer-clean::
	-rm -rf obj_dir logs *.mem *.fst *.vcd *.log *.dmp *.vpd coverage.dat core
