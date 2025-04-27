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

#define MAP_SIZE 16
#define HW_BASE_ADDRESS 0x43C00000

#define TEST_SIZE 1000000

uint32_t monolith_permutation(volatile uint32_t *hw_acc_base, uint32_t value) {
    hw_acc_base[0] = (value << 1) | 1;

    while(1) {
        // TODO: Flush caches in order to get proper value.

        volatile uint32_t read_value = hw_acc_base[2];
        volatile uint32_t output = read_value >> 1;
        volatile uint32_t valid = read_value & 1;

		if (valid) return output;
	}
}

uint32_t rand_inputs[TEST_SIZE] = {0};

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

    printf("Begin computation\n");
    float startTime = (float) clock() / CLOCKS_PER_SEC;
    
    for (uint32_t i = 0; i < TEST_SIZE; i=i+1) {
        volatile uint32_t out = monolith_permutation(acc_base, rand_inputs[i]);
        printf("%d\n", i);
    }
    
    float endTime = (float) clock() / CLOCKS_PER_SEC;
    float timeElapsed = endTime - startTime;
    
    printf("Done!\n");
    printf("Elapsed time: %f\n", timeElapsed);

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
