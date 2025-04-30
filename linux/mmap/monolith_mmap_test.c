#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>     // For uint32_t
#include <sys/mman.h>
#include <fcntl.h>      // For O_RDWR, O_SYNC
#include <unistd.h>     // For close(), sysconf(), _SC_PAGESIZE
#include <errno.h>      // For perror()
#include <inttypes.h>   // For PRIx32 format specifier macro
#include <sched.h>
#include <time.h>
#include <sys/time.h>

#define MAP_SIZE 16
#define HW_BASE_ADDRESS 0x43C00000

#define TEST_SIZE 1000000
#define PRINT_COMPUTATIONS

uint32_t monolith_permutation(volatile uint32_t *hw_acc_base, uint32_t value) {
    hw_acc_base[0] = (value << 1) | 1;

    // Example: For a million computations, about 20-30 calls to this function will return the value from the prev call without this fine tuning code.
    // Below two lines should force flush previous write. 
    volatile uint32_t tmp1 = hw_acc_base[0];
    volatile uint32_t tmp2 = hw_acc_base[2]; 
    
    // Sleep here as to let writes propagate through the OS to the hardware.
    // The peripheral will set the valid flag to 0 when the value changes, earlier reads to the output will read the previous output (BAD!).
    // AXI bus to peripheral runs at ~47MHz (21ns period).
    // CPU runs at 650MHz (~1.53ns period).
    // Linux sleep is at least a few microseconds due to scheduler.
    // Tight loop sleep this since this function will take less than the 100ms sched quanta, so we shouldn't be switched out.
    for (volatile int i = 0; i < 50; i++) {
        asm("MOV r0, r0"); // NOP on ARMv7
    }

    while(1) {
        volatile uint32_t read_value = hw_acc_base[2];
        volatile uint32_t output = read_value >> 1;
        volatile uint32_t valid = read_value & 1;

		if (valid) return output;
	}
}

uint32_t rand_inputs[TEST_SIZE] = {0};
uint32_t outputs[TEST_SIZE] = {0};

int main(int argc, char *argv[argc]) {
    int fd = -1; // Initialize fd to an invalid value
    void *map_base = MAP_FAILED; // Initialize map_base to the error value
    volatile uint32_t* acc_base = NULL;

    fd = open("/dev/mem", O_RDWR | O_SYNC);
    if (fd == -1) {
        perror("Error opening /dev/mem (root privileges?)");
        return EXIT_FAILURE;
    }

    map_base = mmap(0, MAP_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd, HW_BASE_ADDRESS);
    if (map_base == MAP_FAILED) {
        perror("Error mapping memory via mmap");
        close(fd); 
        return EXIT_FAILURE;
    }

    acc_base = (volatile uint32_t*)map_base;

    printf("Begin generating random numbers\n");
    srand(time(NULL));
    for (int i = 0; i < TEST_SIZE; i=i+1) {
        rand_inputs[i] = (uint32_t) rand();
    }

    struct timeval t0, t1;

    printf("Begin computation\n");
    gettimeofday(&t0, NULL);
    for (uint32_t i = 0; i < TEST_SIZE; i=i+1) {
        outputs[i] = monolith_permutation(acc_base, rand_inputs[i]);
    }
    gettimeofday(&t1, NULL); 
    
    double elapsed = t1.tv_sec - t0.tv_sec + 1E-6 * (t1.tv_usec - t0.tv_usec);
    double throughput = TEST_SIZE / elapsed;

    printf("Done!\n");
    printf("Elapsed time: %g s\n", elapsed);
    printf("Throughput: %g hash/sec\n", throughput);

#ifdef PRINT_COMPUTATIONS
    for (int i = 0; i < TEST_SIZE; i=i+1) {
        printf("%d %u %u\n", i, rand_inputs[i], outputs[i]);
    }
#endif

    // Unmap memory
    if (munmap(map_base, MAP_SIZE) == -1) {
        perror("Error unmapping memory");
        // Continue to close fd anyway
    } 

    // Close file descriptor
    if (close(fd) == -1) {
        perror("Error closing /dev/mem file descriptor");
        return EXIT_FAILURE; // Indicate error on close failure
    }

    return EXIT_SUCCESS; // Indicate success
}
