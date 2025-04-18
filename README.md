# Getting started
Vivado projects inside this repository were created using Vivado 2024.2 on a Linux machine. Might not work in other environments.

1. Clone the repository.
2. Change the working directory to work\_dir/.
3. Launch Vivado. Vivado should always be launched from here, as to not pollute other dirs with logs or dumps.
4. Source rebuild\_proj.ctl script. A .xpr project should be created in this directory.
5. Launch simulations, synthesis, etc.

The XPR projects can be discarded after use, as they are not added to version control.
Make sure to rebuild the tcl script from Vivado after changing the projects in any way (e.g. adding/removing files, flow changes, etc.).

The system project will also create some 'garbage' files inside the zynq_system folder. They can also be discarded.

NOTE: For whatever reason, a recreated project using the given script will cause the simulation hierarchy viewer to not be populated correctly. Simulation tops will have crossed out children. This should not affect the simulation itself, it should still run. Does not affect the hierarchy viewer for design sources.

# Project types
Currently there are two project types which can be created:
1. RTL project - includes the bare Monolith hash accelerator, without any special bus interface. A few different testbenches are included to test the various modules present.
2. System project - accelerator is packaged inside a block design along with the Zynq Processing system using a HDL wrapper. Can export a Vitis platform for flashing on a Zynq board.
3. AXI Verification project - For integration with the processing system, the accelerator has been wrapped by a AXI interface. This project use the Xilinx AXI4Lite VIP to verify the integration into a AXI bus.
