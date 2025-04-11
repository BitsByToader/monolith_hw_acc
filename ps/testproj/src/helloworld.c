/******************************************************************************
* Copyright (C) 2023 Advanced Micro Devices, Inc. All Rights Reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/
/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdio.h>
#include "xil_cache.h"
#include "platform.h"
#include "xil_printf.h"

volatile uint32_t *hash_in1 = (uint32_t*) (XPAR_M00_AXI_0_BASEADDR + 0x0);
volatile uint32_t *hash_in2 = (uint32_t*) (XPAR_M00_AXI_0_BASEADDR + 0x4);
volatile uint32_t *hash_ctrl = (uint32_t*) (XPAR_M00_AXI_0_BASEADDR + 0xC);
volatile uint32_t *hash_out = (uint32_t*) (XPAR_M00_AXI_0_BASEADDR + 0x8);

void print_monolith_status() {
	xil_printf("MONOLITH HASH ACC REG STATUS:\r\n");
	xil_printf("Hash in 1: %0X \r\n", *hash_in1);
	xil_printf("Hash in 2: %0X \r\n", *hash_in2);
	xil_printf("Hash ctrl: %0X \r\n", *hash_ctrl);
	xil_printf("Hash out value: %0X. Valid: %0X \r\n\r\n", *hash_out>>1, *hash_out&1);
}

int main()
{
    init_platform();

    while(1) {
    	xil_printf("Resetting hash ctrl...\r\n");
    	Xil_DCacheFlushRange((UINTPTR)hash_in1, 16*sizeof(u32));
    	*hash_ctrl = 0;

    	sleep(5);
    	xil_printf("Out of reset values\r\n");
    	print_monolith_status();
    	sleep(5);

    	xil_printf("Starting a hash and waiting!\r\n");
		Xil_DCacheFlushRange((UINTPTR)hash_in1, 16*sizeof(u32));
    	*hash_in1 = 54;
    	*hash_ctrl = 1; // go in hash mode

    	sleep(5);
    	xil_printf("Results... \r\n");
    	Xil_DCacheFlushRange((UINTPTR)hash_in1, 16*sizeof(u32));
    	print_monolith_status();

		sleep(5);
    }

    cleanup_platform();
    return 0;
}
