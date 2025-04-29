#ifndef ZYNQ_MMIO_CHAR_IOCTL_H
#define ZYNQ_MMIO_CHAR_IOCTL_H

#include <linux/ioctl.h> // Required for _IO macros
#include <linux/types.h> // For __u32

// Define a 'magic' number for the IOCTL commands to ensure uniqueness
#define MY_PERIPHERAL_IOC_MAGIC 'z' // 'z' for Zynq

// Define the structure to pass data between user space and kernel
struct monolith_ioc_hash_data {
    __u32 value; // Value to hash.
    __u32 out; // Hash of value.
};

struct monolith_ioc_compress_data {
    __u32 value1; // Input1 to hash.
    __u32 value2; // Input2 to hash.
    __u32 out; // Compression hash of values.
};

// Define the IOCTL command numbers
// Arg 1: Magic number
// Arg 2: Command number (unique within this driver)
// Arg 3: Type of the argument passed between user/kernel space
#define MONOLITH_IOC_HASH_U32       _IOWR(MY_PERIPHERAL_IOC_MAGIC, 1, struct monolith_ioc_hash_data)
#define MONOLITH_IOC_COMPRESS_U32   _IOWR(MY_PERIPHERAL_IOC_MAGIC, 2, struct monolith_ioc_compress_data)

// Define the maximum command number (used for validation)
#define MY_PERIPHERAL_IOC_MAXNR 2

#endif // ZYNQ_MMIO_CHAR_IOCTL_H
