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
#include "xbasic_types.h"
#include "xscugic.h"
#include "xil_exception.h"
#include "xtime_l.h"

#define INTC_INTERRUPT_ID_0 61 // IRQ_F2P[0:0]

volatile uint32_t *hash_in1 = (uint32_t*) (XPAR_M00_AXI_0_BASEADDR + 0x0);
volatile uint32_t *hash_in2 = (uint32_t*) (XPAR_M00_AXI_0_BASEADDR + 0x4);
volatile uint32_t *hash_out = (uint32_t*) (XPAR_M00_AXI_0_BASEADDR + 0x8);

void print_monolith_status() {
	xil_printf("MONOLITH HASH ACC REG STATUS:\r\n");
	xil_printf("Hash in 1: %0X \r\n", *hash_in1 >> 1);
	xil_printf("Hash in 2: %0X \r\n", *hash_in2 >> 1);
	xil_printf("Hash out value: %0X. Valid: %0X \r\n\r\n", *hash_out>>1, *hash_out&1);
}

void hash_valid_service_routine(void *intc_inst_ptr);

// instance of interrupt controller
static XScuGic intc;

// sets up the interrupt system and enables interrupts for IRQ_F2P[0:0]
// Source: https://github.com/k0nze/zedboard_pl_to_ps_interrupt_example
int setup_interrupt_system() {
    int result;
    XScuGic *intc_instance_ptr = &intc;
    XScuGic_Config *intc_config;

    // get config for interrupt controller
    intc_config = XScuGic_LookupConfig(XPAR_PS7_SCUGIC_0_DEVICE_ID);
    if (NULL == intc_config) {
        return XST_FAILURE;
    }

    // initialize the interrupt controller driver
    result = XScuGic_CfgInitialize(intc_instance_ptr, intc_config, intc_config->CpuBaseAddress);

    if (result != XST_SUCCESS) {
        return result;
    }

    // set the priority of IRQ_F2P[0:0] to 0xA0 (highest 0xF8, lowest 0x00) and a trigger for a rising edge 0x3.
    XScuGic_SetPriorityTriggerType(intc_instance_ptr, INTC_INTERRUPT_ID_0, 0xA0, 0x3);

    // connect the interrupt service routine isr0 to the interrupt controller
    result = XScuGic_Connect(
    		intc_instance_ptr,
			INTC_INTERRUPT_ID_0,
			(Xil_ExceptionHandler)hash_valid_service_routine,
			(void *)&intc
	);

    if (result != XST_SUCCESS) {
        return result;
    }

    // enable interrupts for IRQ_F2P[0:0]
    XScuGic_Enable(intc_instance_ptr, INTC_INTERRUPT_ID_0);

    // initialize the exception table and register the interrupt controller handler with the exception table
    Xil_ExceptionInit();

    Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT, (Xil_ExceptionHandler)XScuGic_InterruptHandler, intc_instance_ptr);

    // enable non-critical exceptions
    Xil_ExceptionEnable();

    return XST_SUCCESS;
}

volatile uint8_t hash_done_flag = 0;

void hash_valid_service_routine(void *intc_inst_ptr) {
	hash_done_flag = 1;
}

int main()
{
    init_platform();
    //setup_interrupt_system();

    XTime time_start, time_end;

    Xil_DCacheFlushRange((UINTPTR)hash_in1, 16*sizeof(u32));

    XTime_GetTime(&time_start);
    for(int i = 0; i < 1000000; i++ ) {
    	hash_done_flag = 0;

    	*hash_in1 = ((1965742212+i) << 1) | 1;

		while ( (*hash_out & 1) == 0 );

		volatile int out = *hash_out >> 1;

//		xil_printf("\r\n--------\r\nHash is now valid!\r\n-----------\r\n");
//		print_monolith_status();
//		sleep(1);
    }
    XTime_GetTime(&time_end);

    xil_printf("Computation took cycles no: %llu \r\n", 2*(time_end-time_start));
    xil_printf("Computation took time: %f us\r\n", (1.0f * (time_end-time_start) / (COUNTS_PER_SECOND/1000000)));

    cleanup_platform();
    return 0;
}
