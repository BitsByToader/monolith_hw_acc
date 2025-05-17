This repository contains the design files of a hardware accelerator for the arithmetizable hash function, [Monolith](https://eprint.iacr.org/2023/1025).
Also provided are sample applications for interfacing with the accelerator via Linux or baremetal.
To check out a Rust-wrapped driver for this accelerator, used in a real STARK to prove/verify arguments of knowledge, check out the [sister repo](https://github.com/BitsByToader/Plonky3/).

# Getting started
Vivado projects inside this repository were created using Vivado 2024.2 on a Linux machine. Might not work in other environments.

1. Clone the repository.
2. Change the working directory to `work\_dir/`.
3. Launch Vivado. Vivado should always be launched from here, as to not pollute other dirs with logs or dumps.
4. Source any of the .tcl scripts. A .xpr project should be created in this directory.
5. Launch simulations, synthesis, etc.

The XPR projects can be discarded after use, as they are not added to version control.
Make sure to rebuild the tcl script from Vivado after changing the projects in any way (e.g. adding/removing files, flow changes, etc.).

The system project will also create some 'garbage' files inside the zynq_system folder. They can also be discarded.

NOTE: For whatever reason, a recreated project using the given script will cause the simulation hierarchy viewer to not be populated correctly. Simulation tops will have crossed out children. This should not affect the simulation itself, it should still run. Does not affect the hierarchy viewer for design sources.

# Project types
Currently there are three project types which can be created:
1. RTL project - includes the bare Monolith hash accelerator, without any special bus interface. A few different testbenches are included to test the various modules present.
2. System project - accelerator is packaged inside a block design along with the Zynq Processing system using an AXI4-Lite HDL wrapper. Can export a Vitis platform for flashing on a Zynq board.
3. AXI Verification project - For integration with the processing system, the accelerator has been wrapped by the same AXI interface. This project use the Xilinx AXI4Lite VIP to verify the integration into a AXI bus.

# Using the accelerator from a baremetal application
1. Use the system project to generate a .xsa platform.
2. Create a platform and application project using the .xsa.
3. the `ps/` folder contains a sample application which benchmarks the accelerator over a batch of 1 million hashes.

# Using the accelerator from Linux
1. Generate a bitstream using the system project.
2. Create the following .bif file with the same name as the bitstream:

```
all:
{
        [bitstream_name].bit /* Bitstream file name */
}
```
4. Create the full bitstream image:

```
bootgen -image [.bif filename].bif -arch zynq -process_bitstream bin
```

6. Download an Ubuntu 22.04 image for the Pynq-Z2 board from [here](https://www.tulembedded.com/FPGA/ProductsPYNQ-Z2.html).
7. Transfer the full bitstream to the board running the Linux image.
8. Copy the full bitstream to `/lib/firmware/`.
9. Load the full bitsream onto the FPGA as `root`:

```
echo [.bit.bin bistream file name] > /sys/class/fpga_manager/fpga0/firmware
```

9.  Use any of the applications from the `linux` folder to interface with the accelerator. The provided samples benchmark the accelerator, and optionally, print the input output pairs for checking them with a reference software implementation of Monolith.

The userspace, polling based driver has been integrated into a full-fledged Rust-based STARK (available [here](https://github.com/BitsByToader/Plonky3)), as it proved to be the fastest method of the three.
The repository contains a playground further benchmarking and validating the outputs of the accelerator and it extends an example proof/verification example flow with the accelerator.
