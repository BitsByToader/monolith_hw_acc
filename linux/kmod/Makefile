# Makefile for On-Target Compilation

# Kernel module object file(s)
# Use the same name as your kernel module C file
obj-m += monolith_hw_acc_char.o

# Path to the kernel source/headers for the currently running kernel
# This relies on kernel headers being installed on the target system!
# The standard location is used here.
KERNEL_SRC := /lib/modules/$(shell uname -r)/build

# Phony targets prevent conflicts with files of the same name
.PHONY: all kernel_module user_app clean load unload run

# Default target: build both the kernel module and the user application
all: kernel_module user_app

# Rule to build the kernel module(s)
# Calls the kernel's build system.
# -C $(KERNEL_SRC): Change directory to the kernel source/headers location.
# M=$(PWD): Tells the kernel build system where your external module source is.
# modules: The target to build within the kernel build system.
kernel_module:
	$(MAKE) -C $(KERNEL_SRC) M=$(PWD) modules

# Rule to build the user-space application
# Uses the target's native GCC compiler.
user_app: user_app.c monolith_hw_acc_char_ioctl.h
	gcc user_app.c -o user_app -Wall -Wextra

# Rule to clean up build artifacts
clean:
	$(MAKE) -C $(KERNEL_SRC) M=$(PWD) clean
	rm -f user_app

# --- Convenience Targets (for use on the target) ---

# Target for loading the module (requires root/sudo on the target)
load: kernel_module
	sudo insmod monolith_hw_acc_char.ko

# Target for unloading the module
unload:
	sudo rmmod monolith_hw_acc_char

# Target to run user app (requires module loaded and permissions potentially set)
run: user_app
	./user_app
