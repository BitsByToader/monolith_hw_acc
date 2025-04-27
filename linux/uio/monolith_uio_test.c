#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <stdint.h>
#include <signal.h>
#include <time.h>

#define REGS_DEVICE "/dev/uio0"
#define IRQ_DEVICE  "/dev/uio1"
#define MAP_SIZE    4096

#define IN1_REG     0
#define IN2_REG     1
#define OUT_REG     2

#define TEST_SIZE   1000000
int rand_inputs[TEST_SIZE] = { 0 };

int uio_fd, fabric_fd;

void ack_irq() {
    int ack = 1;
    ssize_t ret = write(fabric_fd, &ack, sizeof(ack));
    if( ret != sizeof(ack) ) {
        perror("irq setup failed");
        exit(1);
    } 
}

void block_irq() {
    uint32_t irq_count;
    int ret = read(fabric_fd, &irq_count, sizeof(irq_count));
    if (ret != sizeof(irq_count)) {
        perror("read failed");
    }
}

uint32_t monolith_hash(volatile uint32_t *base, uint32_t input) {
    base[IN1_REG] = (input << 1) | 1;
    block_irq();
    volatile uint32_t out = base[OUT_REG] >> 1;
    ack_irq();
    return out;
}

int main() {
    void *regs;
    volatile uint32_t *regs_ptr;

    // Open UIO device for reg access.
    uio_fd = open(REGS_DEVICE, O_RDWR);
    if (uio_fd < 0) {
        perror("Failed to open UIO device");
        return EXIT_FAILURE;
    }

    // Open UIO device for IRQ access.
    fabric_fd = open(IRQ_DEVICE, O_RDWR);
    if (fabric_fd < 0) {
        perror("Failed to open UIO device");
        return EXIT_FAILURE;
    }

    // Memory map device registers
    regs = mmap(NULL, MAP_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, uio_fd, 0);
    if (regs == MAP_FAILED) {
        perror("mmap failed");
        close(uio_fd);
        return EXIT_FAILURE;
    }
    regs_ptr = (volatile uint32_t *)regs;

    // Disable engine.
    regs_ptr[IN1_REG] = 0x00;

    // Enable interrupt by acknoledging it.
    ack_irq();

    printf("Begin generating random numbers\n");
    srand(time(NULL));
    for (int i = 0; i < TEST_SIZE; i=i+1) {
        rand_inputs[i] = (uint32_t) rand();
    }

    printf("Begin computation\n");
    float startTime = (float) clock() / CLOCKS_PER_SEC;

    for (uint32_t i = 0; i < TEST_SIZE; i=i+1) {
        volatile uint32_t out = monolith_hash(regs_ptr, rand_inputs[i]);
        printf("%d\n", i);
    }

    float endTime = (float) clock() / CLOCKS_PER_SEC;
    float timeElapsed = endTime - startTime;

    printf("Done!\n");
    printf("Elapsed time: %f\n", timeElapsed);
    
    // Cleanup
    printf("Exiting...\n");
    munmap((void *)regs_ptr, MAP_SIZE);
    close(uio_fd);
    close(fabric_fd);

    return EXIT_SUCCESS;
}
