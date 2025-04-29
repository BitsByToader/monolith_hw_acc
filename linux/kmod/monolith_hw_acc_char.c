#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/io.h>         // ioremap, ioread32, iowrite32
#include <linux/fs.h>         // file_operations, register_chrdev, etc.
#include <linux/cdev.h>       // Character device definitions
#include <linux/device.h>     // class_create, device_create
#include <linux/uaccess.h>    // copy_from_user, copy_to_user
#include <linux/slab.h>       // kmalloc (though not strictly needed now)
#include <linux/interrupt.h>
#include <linux/wait.h>       // wait queues
#include <linux/sched.h>      // TASK_INTERRUPTIBLE
#include <linux/atomic.h>     // atomic_t

#include "monolith_hw_acc_char_ioctl.h"

// --- Peripheral Configuration ---
#define DRIVER_NAME         "monolith_hw_acc"
#define PERIPH_BASE_ADDR    0x43C00000
#define PERIPH_MAP_SIZE     PAGE_SIZE       // map full page just in case

#define HASH_VALID_IRQ_NO   56

#define MAX_READ_ATTEMPT_NO 100

// --- Register Offsets (example) ---
#define REG_IN1             0x00
#define REG_IN2             0x04
#define REG_OUT             0x08

// --- Global Variables ---
static void __iomem *peripheral_regs = NULL; // Virtual address for peripheral registers
static int major_number = 0;
static struct cdev my_cdev;
static struct class *my_class = NULL;
static struct device *my_device = NULL;
static dev_t my_dev_t; // Holds major/minor numbers

// --- Helper Functions for Register Access ---
static inline u32 periph_read_reg(u32 offset)
{
    if (!peripheral_regs) {
        pr_err("%s: Peripheral not mapped\n", DRIVER_NAME);
        return 0; // TODO: PROPAGATE REAL ERROR
    }
    
    // Ensure offset is within real reg map, not whole page.
    if (offset >= (3 * sizeof(u32))) { // Only 3 registers defined
         pr_warn("%s: Attempt to read offset 0x%x outside defined range\n", DRIVER_NAME, offset);
         return 0; // TODO: REAL ERROR NUMBER.
    }
    
    return ioread32(peripheral_regs + offset);
}

static inline void periph_write_reg(u32 offset, u32 value)
{
    if (!peripheral_regs) {
        pr_err("%s: Peripheral not mapped\n", DRIVER_NAME);
        return;
    }
    
    if (offset >= (3 * sizeof(u32))) {
         pr_warn("%s: Attempt to write offset 0x%x outside defined range\n", DRIVER_NAME, offset);
         return;
    }

    iowrite32(value, peripheral_regs + offset);
}

// --- Interrupt Handler ---
static atomic_t irq_handled = ATOMIC_INIT(0);
static wait_queue_head_t wait_queue;

static inline void reset_irq(void) {
    atomic_set(&irq_handled, 0);
}

static inline u32 ack_irq(void) {
    u32 output_at_irq = periph_read_reg(REG_OUT);

    if ( (output_at_irq&1) == 1 ) {
        // Acknowledge IRQ, by resetting input (same as just setting LSB).
        periph_write_reg(REG_IN1, 0);
    }

    return output_at_irq;
}

static irqreturn_t irq_handler(int irq,void *dev_id) {
    atomic_set(&irq_handled, 1); 
    wake_up_interruptible(&wait_queue);

    //pr_info("%s: Handled IRQ!\n", DRIVER_NAME);

    return IRQ_HANDLED;
}

// --- File Operations ---

static int my_open(struct inode *inode, struct file *file)
{
    pr_info("%s: Device opened\n", DRIVER_NAME);
    // Optional: Increment usage count, allocate per-instance data, etc.
    return 0; // Success
}

static int my_release(struct inode *inode, struct file *file)
{
    pr_info("%s: Device closed\n", DRIVER_NAME);
    // Optional: Decrement usage count, free per-instance data, etc.
    return 0; // Success
}

// The core function for user-space interaction
static long my_ioctl(struct file *file, unsigned int cmd, unsigned long arg)
{
    struct monolith_ioc_hash_data hash_data;
    struct monolith_ioc_compress_data compress_data;
    u32 read_data = -1, read_attempt_count = 0;
    u32 output_at_irq = -1;

    // Verify IOCTL command and arguments based on type and number
    if (_IOC_TYPE(cmd) != MY_PERIPHERAL_IOC_MAGIC) return -ENOTTY; // Wrong magic number
    if (_IOC_NR(cmd) > MY_PERIPHERAL_IOC_MAXNR) return -ENOTTY;  // Command number out of range

    // Check access permissions based on command direction (_IOC_READ, _IOC_WRITE)
    // This checks if the user-provided pointer 'arg' is valid for reading/writing
    if (_IOC_DIR(cmd) & _IOC_READ) {
        if (!access_ok((void __user *)arg, _IOC_SIZE(cmd))) {
             return -EFAULT;
        }
    }
    if (_IOC_DIR(cmd) & _IOC_WRITE) {
         if (!access_ok((void __user *)arg, _IOC_SIZE(cmd))) {
             return -EFAULT;
        }
    }

    // Process the command
    switch (cmd) {
        case MONOLITH_IOC_HASH_U32:
            // Copy the request structure (containing offset) from user space
            if (copy_from_user(&hash_data, (struct monolith_ioc_hash_data __user *)arg, sizeof(hash_data))) {
                pr_err("%s: IOCTL HASH - Failed to copy data from user\n", DRIVER_NAME);
                return -EFAULT;
            }

            // Send hash input.
            pr_debug("%s: Hashing value:  0x%x\n", DRIVER_NAME, hash_data.value);
            periph_write_reg(REG_IN2, 0);
            periph_write_reg(REG_IN1, (hash_data.value<<1)|1);

            // Sleep until results are valid.
            // 4000 nanosecond timeout, how much one computation takes, with some margin (real compt ~2400).
            wait_event_interruptible_timeout(wait_queue, atomic_read(&irq_handled) == 1, usecs_to_jiffies(3));  

            // Will return the value read at the moment of IRQ.
            output_at_irq = ack_irq();
            
            if ( (output_at_irq&1) == 0 ) { // Data invalid.
                hash_data.out = -1;
            } else { // Data valid
                hash_data.out = output_at_irq >> 1; // Remove flag.
            }

            // Copy the updated structure (containing value) back to user space
            if (copy_to_user((struct monolith_ioc_hash_data __user *)arg, &hash_data, sizeof(hash_data))) {
                pr_err("%s: IOCTL HASH - Failed to copy data to user\n", DRIVER_NAME);
                return -EFAULT;
            }

            reset_irq();
            break;

        case MONOLITH_IOC_COMPRESS_U32:
            // Copy the request structure (containing offset) from user space
            if (copy_from_user(&compress_data, (struct monolith_ioc_compress_data __user *)arg, sizeof(compress_data))) {
                pr_err("%s: IOCTL COMPRESS - Failed to copy data from user\n", DRIVER_NAME);
                return -EFAULT;
            }

            // Send hash input.
            pr_debug("%s: Compressing values:  0x%x and 0x%x\n", DRIVER_NAME, compress_data.value1, compress_data.value2);
            periph_write_reg(REG_IN2, (compress_data.value2<<1)|1);
            periph_write_reg(REG_IN1, (compress_data.value1<<1)|1);
            
            // Wait for valid and store result back into struct
            read_data = -1;
            read_attempt_count = 0;
            do {
                read_attempt_count++;
                read_data = periph_read_reg(REG_OUT);
//                pr_debug("%s: Attempt read: 0x%x\n", DRIVER_NAME, read_data);
            } while ( (read_data&1) == 0 && read_attempt_count < MAX_READ_ATTEMPT_NO);
            
            if ( (read_data&1) == 0) {
                compress_data.out = -1; // Invalid data
            } else {
                compress_data.out = read_data >> 1; // Remove valid flag
            }

            // Copy the updated structure (containing value) back to user space
            if (copy_to_user((struct monolith_ioc_compress_data __user *)arg, &compress_data, sizeof(compress_data))) {
                pr_err("%s: IOCTL COMPRESS - Failed to copy data to user\n", DRIVER_NAME);
                return -EFAULT;
            }
            break;

        default:
            pr_warn("%s: IOCTL - Unknown command received: 0x%x\n", DRIVER_NAME, cmd);
            return -ENOTTY; // Command not implemented
    }

    return 0; // Success
}


// Structure linking file operations to our functions
static const struct file_operations my_fops = {
    .owner          = THIS_MODULE,
    .open           = my_open,
    .release        = my_release,
    .unlocked_ioctl = my_ioctl,
    // Add .read and .write here if you want direct read/write syscalls
    // but ioctl is generally more flexible for register access.
};


// --- Module Init Function ---
static int __init my_peripheral_init(void)
{
    int ret = 0;

    pr_info("%s: Initializing...\n", DRIVER_NAME);
    
    // Initialize wait queue used to sleep this process while waiting for computation.
    init_waitqueue_head(&wait_queue);

    // Map peripheral address into virtual addr space.
    if (!request_mem_region(PERIPH_BASE_ADDR, PERIPH_MAP_SIZE, DRIVER_NAME)) {
        pr_err("%s: Failed to request memory region 0x%lx\n", DRIVER_NAME, (unsigned long)PERIPH_BASE_ADDR);
        return -EBUSY;
    }

    peripheral_regs = ioremap(PERIPH_BASE_ADDR, PERIPH_MAP_SIZE);
    if (!peripheral_regs) {
        pr_err("%s: Failed to ioremap address 0x%lx\n", DRIVER_NAME, (unsigned long)PERIPH_BASE_ADDR);
        ret = -ENOMEM;
        goto cleanup_region;
    }
    pr_info("%s: Peripheral mapped at virtual address %p\n", DRIVER_NAME, peripheral_regs);

    // Allocate a major number dynamically
    ret = alloc_chrdev_region(&my_dev_t, 0, 1, DRIVER_NAME); // Base minor 0, 1 device
    if (ret < 0) {
        pr_err("%s: Failed to allocate chrdev region\n", DRIVER_NAME);
        goto cleanup_ioremap;
    }
    major_number = MAJOR(my_dev_t);
    pr_info("%s: Registered char device with major number %d\n", DRIVER_NAME, major_number);

    // Initialize the cdev structure and link it to our file operations
    cdev_init(&my_cdev, &my_fops);
    my_cdev.owner = THIS_MODULE;

    // Add the character device to the system
    ret = cdev_add(&my_cdev, my_dev_t, 1); // Add 1 device
    if (ret < 0) {
        pr_err("%s: Failed to add cdev\n", DRIVER_NAME);
        goto cleanup_chrdev_region;
    }

    // Create a device class (visible in /sys/class/)
    my_class = class_create(THIS_MODULE, DRIVER_NAME);
    if (IS_ERR(my_class)) {
        ret = PTR_ERR(my_class);
        pr_err("%s: Failed to create device class\n", DRIVER_NAME);
        goto cleanup_cdev;
    }
    pr_info("%s: Device class created\n", DRIVER_NAME);

    // Create the device node (/dev/monolith_hw_acc) associated with our cdev
    my_device = device_create(my_class, NULL, my_dev_t, NULL, DRIVER_NAME);
    if (IS_ERR(my_device)) {
        ret = PTR_ERR(my_device);
        pr_err("%s: Failed to create device node\n", DRIVER_NAME);
        goto cleanup_class;
    }
    pr_info("%s: Device node /dev/%s created\n", DRIVER_NAME, DRIVER_NAME);

    // Register IRQ for data valid from the hash engine.
    if (request_irq(HASH_VALID_IRQ_NO, irq_handler, 0, "monolith_valid", (void *)(irq_handler))) {
        pr_err("%s: IRQ register failed!\n", DRIVER_NAME);
        goto cleanup_class;
    }
    pr_info("%s: IRQ registered!\n", DRIVER_NAME);

    pr_info("%s: Initialization complete.\n", DRIVER_NAME);
    return 0; // Success

    // --- Error Handling Cleanup ---
cleanup_class:
    class_destroy(my_class);
cleanup_cdev:
    cdev_del(&my_cdev);
cleanup_chrdev_region:
    unregister_chrdev_region(my_dev_t, 1);
cleanup_ioremap:
    iounmap(peripheral_regs);
    peripheral_regs = NULL;
cleanup_region:
    release_mem_region(PERIPH_BASE_ADDR, PERIPH_MAP_SIZE);

    pr_err("%s: Initialization failed with error %d\n", DRIVER_NAME, ret);
    return ret;
}

// --- Module Exit Function ---
static void __exit my_peripheral_exit(void)
{
    pr_info("%s: Exiting...\n", DRIVER_NAME);

    // --- Clean up IRQ ---
    // First, as to not receive anything while cleaning up.
    free_irq(HASH_VALID_IRQ_NO, (void *)(irq_handler));
    pr_info("%s: Released valid IRQ.\n", DRIVER_NAME);

    atomic_set(&irq_handled, 1);
    wake_up_interruptible(&wait_queue);

    // --- Clean up Character Device ---
    if (my_device) {
        device_destroy(my_class, my_dev_t);
        my_device = NULL;
        pr_info("%s: Device node destroyed\n", DRIVER_NAME);
    }
    if (my_class) {
        class_destroy(my_class);
        my_class = NULL;
        pr_info("%s: Device class destroyed\n", DRIVER_NAME);
    }
    cdev_del(&my_cdev);
    pr_info("%s: Cdev removed\n", DRIVER_NAME);
    unregister_chrdev_region(my_dev_t, 1);
    pr_info("%s: Char device region unregistered\n", DRIVER_NAME);


    // --- Unmap Peripheral ---
    if (peripheral_regs) {
        pr_info("%s: Unmapping peripheral registers...\n", DRIVER_NAME);
        iounmap(peripheral_regs);
        peripheral_regs = NULL;
    }

    // --- Release Memory Region ---
    pr_info("%s: Releasing memory region 0x%lx...\n", DRIVER_NAME, (unsigned long)PERIPH_BASE_ADDR);
    release_mem_region(PERIPH_BASE_ADDR, PERIPH_MAP_SIZE);

    pr_info("%s: Cleanup complete.\n", DRIVER_NAME);
}

module_init(my_peripheral_init);
module_exit(my_peripheral_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Tudor Ifrim");
MODULE_DESCRIPTION("Monolith hash accelerator driver.");
