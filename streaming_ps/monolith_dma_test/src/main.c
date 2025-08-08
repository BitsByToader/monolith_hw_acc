#include "xaxidma.h"
#include "xparameters.h"
#include "xdebug.h"
#include "sleep.h"
#include "xiltimer.h"

#define DMA_DEV_ID		XPAR_AXIDMA_0_DEVICE_ID

#define DDR_BASE_ADDR       XPAR_PSU_DDR_0_BASEADDRESS
#define MEM_BASE_ADDR		(DDR_BASE_ADDR + 0x1000000)

#define TX_BUFFER_BASE		(MEM_BASE_ADDR + 0x00100000)
#define RX_BUFFER_BASE		(MEM_BASE_ADDR + 0x00300000)
#define RX_BUFFER_HIGH		(MEM_BASE_ADDR + 0x004FFFFF)

#define PERM_FFE_COUNT		16
#define PERM_LEN			PERM_FFE_COUNT*sizeof(u32)

XAxiDma AxiDma;

int XAxiDma_Polling_Setup(UINTPTR BaseAddress) {
    XAxiDma_Config *CfgPtr;
    int Status;

    /* Initialize the XAxiDma device.
	 */
	CfgPtr = XAxiDma_LookupConfig(BaseAddress);
	if (!CfgPtr) {
		xil_printf("No config found for %d\r\n", BaseAddress);
		return XST_FAILURE;
	}

	Status = XAxiDma_CfgInitialize(&AxiDma, CfgPtr);
	if (Status != XST_SUCCESS) {
		xil_printf("Initialization failed %d\r\n", Status);
		return XST_FAILURE;
	}

	if (XAxiDma_HasSg(&AxiDma)) {
		xil_printf("Device configured as SG mode \r\n");
		return XST_FAILURE;
	}

	/* Disable interrupts, we use polling mode
	 */
	XAxiDma_IntrDisable(&AxiDma, XAXIDMA_IRQ_ALL_MASK,
			    XAXIDMA_DEVICE_TO_DMA);
	XAxiDma_IntrDisable(&AxiDma, XAXIDMA_IRQ_ALL_MASK,
			    XAXIDMA_DMA_TO_DEVICE);

    return XST_SUCCESS;
}

int hash_mem_poll(u32 *to_device_mem, u32 *from_device_mem, u32 length) {
	int Status;

	/* Flush the buffers before the DMA transfer, in case the Data Cache
	 * is enabled
	 */
	Xil_DCacheFlushRange((UINTPTR)to_device_mem, length);
	Xil_DCacheFlushRange((UINTPTR)from_device_mem, length);

	// Initiate receiving transfer in anticipation of compute.
	// Reversing the order of the transfers locks up the DMA engine.
	Status = XAxiDma_SimpleTransfer(&AxiDma,
        (UINTPTR) from_device_mem, length,
        XAXIDMA_DEVICE_TO_DMA
    );

	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	// Initiate sending transfer to fetch inputs into accelerator.
	Status = XAxiDma_SimpleTransfer(&AxiDma,
        (UINTPTR) to_device_mem, length,
        XAXIDMA_DMA_TO_DEVICE
    );

	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	while (
        XAxiDma_Busy(&AxiDma, XAXIDMA_DEVICE_TO_DMA) &&
        XAxiDma_Busy(&AxiDma, XAXIDMA_DMA_TO_DEVICE)
    ) {};

	return XST_SUCCESS;
}

int main() {
	int Status;
    XTimer timer;
    XTime time_start, time_end;

    XilTickTimer_Init(&timer);

	Status = XAxiDma_Polling_Setup(XPAR_XAXIDMA_0_BASEADDR);
	if (Status != XST_SUCCESS) {
		xil_printf("XAxiDma_Polling_Setup Failed\r\n");
		return XST_FAILURE;
	}

    XTime_GetTime(&time_start);
    // 1mil hashes of whatever garbage is in memory.
    Status = hash_mem_poll((u32*)TX_BUFFER_BASE, (u32*)RX_BUFFER_BASE, sizeof(u32)*16*1000000);
	XTime_GetTime(&time_end);

    if (Status != XST_SUCCESS) {
		xil_printf("Polling hash failed Failed\r\n");
		return XST_FAILURE;
	}

    xil_printf("Computation took cycles no: %llu \r\n", 2*(time_end-time_start));
    xil_printf("Computation took time: %f us\r\n", (1.0f * (time_end-time_start) / (COUNTS_PER_SECOND/1000000.0)));

	xil_printf("--- Exiting main() --- \r\n");

	return XST_SUCCESS;

}