# Getting started
NOTE: This project was created using Vivado 2024.2 on a Linux machine. Might not work in other environments.

1. Clone the repository.
2. Change the working directory to work\_dir/.
3. Launch Vivado. Vivado should always be launched from here, as to not pollute other dirs with logs or dumps.
4. Source rebuild\_proj.ctl script. A .xpr project should be created in this directory.
5. Launch simulations, synthesis, etc.

The XPR project can be discarded after use, as it's not added to version control.
Make sure to rebuild the tcl script from Vivado after changing the project in any way (e.g. adding/removing files, flow changes, etc.).
