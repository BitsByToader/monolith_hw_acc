#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>      // open()
#include <unistd.h>     // close()
#include <sys/ioctl.h>  // ioctl()
#include <errno.h>      // errno
#include <string.h>     // strerror
#include <time.h>
#include <stdint.h>     // for uint32_t

// Include the SAME header file used by the kernel module
#include "monolith_hw_acc_char_ioctl.h"

// --- Define peripheral details matching the driver ---
#define DEVICE_PATH "/dev/monolith_hw_acc"

#define TEST_SIZE 10
#define PRINT_HASHES

uint32_t rand_inputs[TEST_SIZE] = { 0 };

int driver_fd;
uint32_t monolith_hash(uint32_t input) {
    struct monolith_ioc_hash_data hash_req;
    int ret;

    hash_req.value = input;
    hash_req.out = -1;

    ret = ioctl(driver_fd, MONOLITH_IOC_HASH_U32, &hash_req);
    if (ret < 0) {
        perror("IOCTL Read failed");
        fprintf(stderr, "Error during IOCTL Read: %s\n", strerror(errno));
        close(driver_fd);
        return EXIT_FAILURE;
    }

    return hash_req.out;
}

int main() {

    printf("User App: Opening device: %s\n", DEVICE_PATH);
    driver_fd = open(DEVICE_PATH, O_RDWR); // Open for reading and writing
    if (driver_fd < 0) {
        perror("Failed to open device");
        fprintf(stderr, "Error opening %s: %s\n", DEVICE_PATH, strerror(errno));
        fprintf(stderr, "Did you load the kernel module (sudo insmod)?\n");
        fprintf(stderr, "Do you have permissions (check ls -l /dev/monolith_hw_acc)?\n");
        return EXIT_FAILURE;
    }
    printf("User App: Device opened successfully (fd=%d).\n", driver_fd);

    // --- Benchmark one million hashes ---
    printf("Begin generating random numbers\n");
    srand(time(NULL));
    for (int i = 0; i < TEST_SIZE; i=i+1) {
        rand_inputs[i] = (uint32_t) rand();
    }

    printf("Begin computation\n");
    float startTime = (float) clock() / CLOCKS_PER_SEC;
    int misses = 0;
    for (uint32_t i = 0; i < TEST_SIZE; i=i+1) {
        //volatile uint32_t out = monolith_hash(rand_inputs[i]);
        volatile uint32_t out = monolith_hash(0x36+i);
        if (out == -1) misses++;

        #ifdef PRINT_HASHES
            printf("hash(0x%x)=0x%x\n", 0x36+i, out);
        #endif
    }

    float endTime = (float) clock() / CLOCKS_PER_SEC;
    float timeElapsed = endTime - startTime;

    printf("Done!\n");
    printf("Elapsed time: %f\n", timeElapsed);
    printf("Misses: %d out of %d\n", misses, TEST_SIZE);

    //printf("User App: IOCTL Hash succesfull: Out=0x%08x\n", monolith_hash(0x36));

    printf("User App: Closing device.\n");
    close(driver_fd);

    return EXIT_SUCCESS;
}
