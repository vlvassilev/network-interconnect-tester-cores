//#error 1

/******************************************************************************
*
* Copyright (C) 2015 -18 Xilinx, Inc.  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*
*
*
******************************************************************************/

/*****************************************************************************/
/**
*
* @file xfsbl_hooks.c
*
* This is the file which contains FSBL hook functions.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who  Date        Changes
* ----- ---- -------- -------------------------------------------------------
* 1.00  kc   04/21/14 Initial release
* 2.0   bv   12/05/16 Made compliance to MISRAC 2012 guidelines
*       ssc  03/25/17 Set correct value for SYSMON ANALOG_BUS register
*
* </pre>
*
* @note
*
******************************************************************************/
/***************************** Include Files *********************************/
#include "xfsbl_hw.h"
#include "xfsbl_hooks.h"
#include "psu_init.h"
#include "sleep.h"
#include "xparameters.h"

#ifdef XPAR_XAXIETHERNET_NUM_INSTANCES
#include "xaxiethernet.h"
#else
#include "xemacps.h"
#endif

/************************** Constant Definitions *****************************/
#define PHY_TI_IDENTIFIER					0x2000

/* TI DP83867 PHY Registers */
#define DP83867_R32_RGMIICTL1					0x32
#define DP83867_R86_RGMIIDCTL					0x86

#define TI_PHY_REGCR			0xD
#define TI_PHY_ADDDR			0xE
#define TI_PHY_PHYCTRL			0x10
#define TI_PHY_CFGR2			0x14
#define TI_PHY_SGMIITYPE		0xD3
#define TI_PHY_CFGR2_SGMII_AUTONEG_EN	0x0080
#define TI_PHY_SGMIICLK_EN		0x4000
#define TI_PHY_REGCR_DEVAD_EN		0x001F
#define TI_PHY_REGCR_DEVAD_DATAEN	0x4000
#define TI_PHY_CFGR2_MASK		0x003F
#define TI_PHY_REGCFG4			0x0031
#define TI_PHY_RGMIICTL			0x0032
#define TI_PHY_REGCR_DATA		0x401F
#define TI_PHY_CFG4RESVDBIT7		0x80
#define TI_PHY_CFG4RESVDBIT8		0x100
#define TI_PHY_CFG4_AUTONEG_TIMER	0x60
#define TI_PHY_10M_SGMII_CFG		0x016F

/* TI DP83867 PHY Masks */
#define TI_PHY_CFG2_SPEEDOPT_10EN          0x0040
#define TI_PHY_CFG2_SGMII_AUTONEGEN        0x0080
#define TI_PHY_CFG2_SPEEDOPT_ENH           0x0100
#define TI_PHY_CFG2_SPEEDOPT_CNT           0x0800
#define TI_PHY_CFG2_SPEEDOPT_INTLOW        0x2000
#define TI_PHY_10M_SGMII_RATE_ADAPT		   0x0080
#define TI_PHY_CR_SGMII_EN				   0x0800
#define TI_PHY_CFG4_SGMII_AN_TIMER         0x0060

/* Control register masks for PCS/PMA SGMII core */
#define IEEE_CTRL_RESET_MASK                   	0x8000
#define IEEE_CTRL_LOOPBACK_MASK                	0x4000
#define IEEE_CTRL_SPEED_LSB_MASK               	0x2000
#define IEEE_CTRL_AUTONEG_MASK                  0x1000
#define IEEE_CTRL_PWRDOWN_MASK                  0x0800
#define IEEE_CTRL_ISOLATE_MASK                  0x0400
#define IEEE_CTRL_RESTART_AN_MASK               0x0200
#define IEEE_CTRL_DUPLEX_MASK               	0x0100
#define IEEE_CTRL_COLLISION_MASK               	0x0080
#define IEEE_CTRL_SPEED_MSB_MASK               	0x0040
#define IEEE_CTRL_UNIDIRECTIONAL_MASK           0x0020

/* Registers for PCS/PMA SGMII core */
#define PHY_CTRL_REG	  						0
#define PHY_STATUS_REG  						1
#define PHY_IDENTIFIER_1_REG					2
#define PHY_IDENTIFIER_2_REG					3
#define PHY_DETECT_MASK 					0x1808
#define PHY_TI_IDENTIFIER					0x2000
#define PHY_XILINX_PCS_PMA_ID1			0x0174
#define PHY_XILINX_PCS_PMA_ID2			0x0C00

/* PS GPIO register offsets */
// * GEM design: SGMII core reset driven by pl_resetn0 (GPIO bank 5, bit 31)
//               PHY resets driven by GPIO bank 3, bits 0-3
// * AXI Eth design: SGMII core reset driven by pl_resetn1 (GPIO bank 5, bit 30)
//               PHY resets driven by the AXI Ethernet cores
#define GPIO_DIRM_BANK_0     0xFF0A0204
#define GPIO_DIRM_BANK_1     0xFF0A0244
#define GPIO_DIRM_BANK_2     0xFF0A0284
#define GPIO_DIRM_BANK_3     0xFF0A02C4
#define GPIO_DIRM_BANK_4     0xFF0A0304
#define GPIO_DIRM_BANK_5     0xFF0A0344
#define GPIO_OPEN_BANK_0     0xFF0A0208
#define GPIO_OPEN_BANK_1     0xFF0A0248
#define GPIO_OPEN_BANK_2     0xFF0A0288
#define GPIO_OPEN_BANK_3     0xFF0A02C8
#define GPIO_OPEN_BANK_4     0xFF0A0308
#define GPIO_OPEN_BANK_5     0xFF0A0348
#define GPIO_DATA_BANK_0     0XFF0A0040
#define GPIO_DATA_BANK_1     0XFF0A0044
#define GPIO_DATA_BANK_2     0XFF0A0048
#define GPIO_DATA_BANK_3     0XFF0A004C
#define GPIO_DATA_BANK_4     0XFF0A0050
#define GPIO_DATA_BANK_5     0XFF0A0054
#define GPIO_EMIO_0_MASK     0x00000001
#define GPIO_EMIO_1_MASK     0x00000002
#define GPIO_EMIO_2_MASK     0x00000004
#define GPIO_EMIO_3_MASK     0x00000008
#define GPIO_PL_RESETN0_MASK 0x80000000
#define GPIO_PL_RESETN1_MASK 0x40000000

/**************************** Type Definitions *******************************/

/***************** Macros (Inline Functions) Definitions *********************/

/************************** Function Prototypes ******************************/

/************************** Variable Definitions *****************************/

// External PHY addresses on 96B Quad Ethernet Mezzanine
const u16 extphyaddr[4] = {0x1,0x3,0xC,0xF};
// SGMII PHY addresses determined in Vivado design
const u16 sgmiiphyaddr[5] = {0x2,0x4,0xD,0x10,0x11};

#ifdef XPAR_XAXIETHERNET_NUM_INSTANCES
typedef XAxiEthernet MacType;
typedef XAxiEthernet_Config MacConfigType;
extern XAxiEthernet_Config XAxiEthernet_ConfigTable[];
XAxiEthernet_Config* Mac_ConfigTable = XAxiEthernet_ConfigTable;
#define Generic_CfgInitialize(a,b,c) XAxiEthernet_CfgInitialize(a,b,c)
#define Generic_SetMdioDivisor(a,b) XAxiEthernet_PhySetMdioDivisor(a,b)
#define Generic_PhyRead(a,b,c,d) XAxiEthernet_PhyRead(a,b,c,d)
#define Generic_PhyWrite(a,b,c,d) XAxiEthernet_PhyWrite(a,b,c,d)
#define MAC_W_MDIO_BASEADDR XPAR_AXI_ETHERNET_0_BASEADDR
#define MAC_NUM_INSTANCES XPAR_XAXIETHERNET_NUM_INSTANCES
#define MDIO_CLK_DIVISOR 49
#else
typedef XEmacPs MacType;
typedef XEmacPs_Config MacConfigType;
extern XEmacPs_Config XEmacPs_ConfigTable[];
XEmacPs_Config* Mac_ConfigTable = XEmacPs_ConfigTable;
#define Generic_CfgInitialize(a,b,c) XEmacPs_CfgInitialize(a,b,c)
#define Generic_SetMdioDivisor(a,b) XEmacPs_SetMdioDivisor(a,b)
#define Generic_PhyRead(a,b,c,d) XEmacPs_PhyRead(a,b,c,d)
#define Generic_PhyWrite(a,b,c,d) XEmacPs_PhyWrite(a,b,c,d)
#define MAC_W_MDIO_BASEADDR XPAR_XEMACPS_0_BASEADDR
#define MAC_NUM_INSTANCES XPAR_XEMACPS_NUM_INSTANCES
#define MDIO_CLK_DIVISOR 7
#endif

#ifdef XFSBL_BS
u32 XFsbl_HookBeforeBSDownload(void )
{
	u32 Status = XFSBL_SUCCESS;

	/**
	 * Add the code here
	 */


	return Status;
}


u32 XFsbl_HookAfterBSDownload(void )
{
	u32 Status = XFSBL_SUCCESS;

	/**
	 * Add the code here
	 */

	return Status;
}
#endif

/* Extended Read function for PHY registers above 0x001F */
static void PhyReadExtended(MacType *macp, u16 phy_addr, u16 reg, u16 *pvalue)
{
	u16 PhyAddr = phy_addr & 0x001f;
	Generic_PhyWrite(macp, PhyAddr, TI_PHY_REGCR, 0x001f );
	Generic_PhyWrite(macp, PhyAddr, TI_PHY_ADDDR, reg );
	Generic_PhyWrite(macp, PhyAddr, TI_PHY_REGCR, 0x401f);
	Generic_PhyRead(macp, PhyAddr, TI_PHY_ADDDR, pvalue);
}

/* Extended Write function for PHY registers above 0x001F */
static void PhyWriteExtended(MacType *macp, u16 phy_addr, u16 reg, u16 value)
{
	u16 PhyAddr = phy_addr & 0x001f;
	u16 tmp;
	Generic_PhyWrite(macp, PhyAddr, TI_PHY_REGCR, 0x001f );
	Generic_PhyWrite(macp, PhyAddr, TI_PHY_ADDDR, reg );
	Generic_PhyWrite(macp, PhyAddr, TI_PHY_REGCR, 0x401f);
	Generic_PhyWrite(macp, PhyAddr, TI_PHY_ADDDR, value);
	/* Read-back and verify */
	Generic_PhyRead(macp, PhyAddr, TI_PHY_ADDDR, &tmp);
	if( tmp != value )
		xil_printf("ERROR: PHYWriteExtended read-back verification failed!\r\n");
}

/*
 * init_dp83867_phy: Initialize DP83867 PHY
 *
 * There are a few things that need to be configured in the
 * DP83867 PHY for optimal operation:
 * - Enable 10Mbps operation (clear bit 7 of register 0x016F)
 * - Set SGMII Auto-negotiation timer to 11ms
 * - Disable RGMII
 *
 * Note that these configurations will be done by the DP83867 driver
 * when the ports are first initialized (eg. ifconfig eth0 up) but
 * we also want to do them here in the FSBL so that U-boot can make
 * full use of the ports.
 */
static void init_dp83867_phy(MacType *macp, u32 phy_addr)
{
	u16 control;

	// Enable 10Mbps operation
	PhyReadExtended(macp, phy_addr, TI_PHY_10M_SGMII_CFG, &control);
	control &= ~(TI_PHY_10M_SGMII_RATE_ADAPT);
	PhyWriteExtended(macp, phy_addr, TI_PHY_10M_SGMII_CFG, control);

	// Set SGMII autonegotiation timer to 11ms
	PhyReadExtended(macp, phy_addr, TI_PHY_REGCFG4, &control);
	control |= TI_PHY_CFG4_SGMII_AN_TIMER;
	PhyWriteExtended(macp, phy_addr, TI_PHY_REGCFG4, control);

	// Disable RGMII
	PhyWriteExtended(macp, phy_addr, TI_PHY_RGMIICTL, 0x0);
}

/*
 * ps_gpio_set: Set PS GPIO output(s)
 * 
 * This function will configure the specified GPIOs as outputs
 * and set their value as requested.
 * 
 * Arguments:  bank - the GPIO bank number (0,1,2,3,4,5)
 *             mask - bit mask for selecting targeted GPIO(s)
 *             value - values to set the targeted GPIO(s)
 */
unsigned ps_gpio_set(u32 bank,u32 mask,u32 value)
{
	const u32 dirm[6] = {GPIO_DIRM_BANK_0,GPIO_DIRM_BANK_1,GPIO_DIRM_BANK_2,
			GPIO_DIRM_BANK_3,GPIO_DIRM_BANK_4,GPIO_DIRM_BANK_5};
	const u32 open[6] = {GPIO_OPEN_BANK_0,GPIO_OPEN_BANK_1,GPIO_OPEN_BANK_2,
			GPIO_OPEN_BANK_3,GPIO_OPEN_BANK_4,GPIO_OPEN_BANK_5};
	const u32 data[6] = {GPIO_DATA_BANK_0,GPIO_DATA_BANK_1,GPIO_DATA_BANK_2,
			GPIO_DATA_BANK_3,GPIO_DATA_BANK_4,GPIO_DATA_BANK_5};

	u32 reg = 0;
	// Set as outputs
	reg = *(volatile u32 *)(dirm[bank]);
	reg |= mask;
	*(volatile u32 *)(dirm[bank]) = reg;
	// Enable outputs
	reg = *(volatile u32 *)(open[bank]);
	reg |= mask;
	*(volatile u32 *)(open[bank]) = reg;
	// Set to value
	reg = *(volatile u32 *)(data[bank]);
	reg |= (value & mask);
	reg &= ~(~value & mask);
	*(volatile u32 *)(data[bank]) = reg;
	return 0;
}

u32 XFsbl_HookBeforeHandoff(u32 EarlyHandoff)
{
	u32 Status = XFSBL_SUCCESS;

	/**
	 * Add the code here
	 */
	MacType mac_with_mdio[MAC_NUM_INSTANCES];
	MacConfigType *mac_config_p = NULL;
	u16 control;
	u32 i;
	u32 t;
	u32 sgmii_rst_mask;

	// GPIO mask for resetting SGMII core - SGMII core reset connected to:
	// - pl_resetn0 (active low) on GEM design, EMIO GPIO bank 5, bit 31, EMIO[95]
	// - pl_resetn1 (active low) on AXI Ethernet design, EMIO GPIO bank 5, bit 30, EMIO[94]
	sgmii_rst_mask = 0x80000000;
#ifdef XPAR_XAXIETHERNET_NUM_INSTANCES
	sgmii_rst_mask >>= 1;
#endif

	// First initialize the MAC with the MDIO interface
	u32 result = XST_SUCCESS;
	// Obtain config of the MAC with the MDIO interface
	for (i = 0; i < MAC_NUM_INSTANCES; i++) {
	mac_config_p = &Mac_ConfigTable[i];

	// Exit if we did not find the MAC with MDIO interface
	if (mac_config_p == NULL) {
		XFsbl_Printf(DEBUG_PRINT_ALWAYS,"96BQuadEthernet: Could not find GEM0 config table");
		return(Status);
	}

	// Initialize MAC with MDIO interface
	result = Generic_CfgInitialize(&mac_with_mdio[i], mac_config_p,
						mac_config_p->BaseAddress);
	if (result != XST_SUCCESS) {
		XFsbl_Printf(DEBUG_PRINT_ALWAYS,"96BQuadEthernet: In %s:MAC Configuration Failed....\r\n", __func__);
	}

	// Set the MDIO clock divisor
	Generic_SetMdioDivisor(&mac_with_mdio[i], MDIO_CLK_DIVISOR);

        } //end loop

	// Assert SGMII core reset (active low)
	XFsbl_Printf(DEBUG_PRINT_ALWAYS,"96BQuadEthernet: Assert SGMII core reset\n\r");
	ps_gpio_set(5,sgmii_rst_mask,0x0);

	XFsbl_Printf(DEBUG_PRINT_ALWAYS,"96BQuadEthernet: Hard reset external PHYs\n\r");
#ifdef XPAR_XAXIETHERNET_NUM_INSTANCES
	// FOR THE AXI ETHERNET DESIGNS - RESET PHY3
	// Assert external PHY reset for port 3: connected to pl_resetn2
	// pl_resetn2 is GPIO bank 5, bit 29, EMIO[93]
	// The PHYs on ports 0,1,2 will be reset automatically by their respective AXI Ethernet cores
	ps_gpio_set(5,0x20000000,0x00000000); // GPIO value = LOW
	usleep(10000);
	ps_gpio_set(5,0x20000000,0x20000000); // GPIO value = HIGH
#else
	// FOR THE GEM DESIGNS - RESET ALL PHYs
	// Assert external PHY resets: connected to EMIO GPIO[0-3]
	// EMIO[0-3] is GPIO bank 3, bits 0-3
	ps_gpio_set(3,0x0000000F,0x00000000); // GPIO value = LOW
	usleep(10000);
	ps_gpio_set(3,0x0000000F,0x0000000F); // GPIO value = HIGH
#endif
	usleep(5000);

	// Enable the 625MHz clock output on external PHY of port 3 (addr 15)
	// This clock is required by the SGMII cores of ALL PORTS
	XFsbl_Printf(DEBUG_PRINT_ALWAYS,"96BQuadEthernet: Enable 625MHz clock output\n\r");

	for (i = 0; i < MAC_NUM_INSTANCES; i++) {
	// Make sure that we can read from the external PHY
	Generic_PhyRead(&mac_with_mdio[i], extphyaddr[3], PHY_IDENTIFIER_1_REG, &control);
	// If we don't read the correct TI identifier, then we flag the issue
	// but we continue to release SGMII core from reset
	if(control != PHY_TI_IDENTIFIER) {
		XFsbl_Printf(DEBUG_PRINT_ALWAYS,"96BQuadEthernet: External PHY returned ID 0x%04X. Failed to enable SGMII clock.\r\n",control);
	}
	else {
		// Enable SGMII Clock
		PhyReadExtended(&mac_with_mdio[i],extphyaddr[3],TI_PHY_SGMIITYPE,&control);
		control |= TI_PHY_SGMIICLK_EN;
		PhyWriteExtended(&mac_with_mdio[i],extphyaddr[3],TI_PHY_SGMIITYPE,control);

		// If we failed to enable the clock, then we flag the issue and continue
		// to release the SGMII core from reset
		PhyReadExtended(&mac_with_mdio[i],extphyaddr[3],TI_PHY_SGMIITYPE,&control);
		if((control & TI_PHY_SGMIICLK_EN) == 0){
			XFsbl_Printf(DEBUG_PRINT_ALWAYS,"96BQuadEthernet: Failed to enable SGMII clock (0x%04X)\n\r",control);
		}
		// Otherwise we wait for the clock to stabilize before releasing
		// the SGMII core from reset
		else {
			usleep(500);
		}
	}
	} //end loop
	// Release SGMII core reset
	XFsbl_Printf(DEBUG_PRINT_ALWAYS,"96BQuadEthernet: Release SGMII core reset\n\r");
	ps_gpio_set(5,sgmii_rst_mask,sgmii_rst_mask);

	usleep(1000000);

	// No auto-negotiation, full duplex, 1Gbps
	for (i = 0; i < MAC_NUM_INSTANCES; i++) {
		mac_config_p = &Mac_ConfigTable[i];
		Generic_PhyWrite(&mac_with_mdio[i], 1, PHY_CTRL_REG,
				IEEE_CTRL_DUPLEX_MASK | IEEE_CTRL_SPEED_MSB_MASK |
				IEEE_CTRL_UNIDIRECTIONAL_MASK);
		Generic_PhyWrite(&mac_with_mdio[i], 2, PHY_CTRL_REG,
				IEEE_CTRL_DUPLEX_MASK | IEEE_CTRL_SPEED_MSB_MASK |
				IEEE_CTRL_UNIDIRECTIONAL_MASK);
		XFsbl_Printf(DEBUG_PRINT_ALWAYS,"[%d] No auto-negotiation, full duplex, 1Gbps\n\r", i);
	}
	return Status;
#if 0
	XFsbl_Printf(DEBUG_PRINT_ALWAYS,"Enabling traffic-generator on port 0\n\r");
	XFsbl_Printf(DEBUG_PRINT_ALWAYS,"0xA0180000=0x%08X\n\r",*(volatile u32 *)(0xA0180000));
	*(volatile u32 *)(0xA0180008) = 2;
	//usleep(1000000);
	//XFsbl_Printf(DEBUG_PRINT_ALWAYS,"Enabling loopback on port 0\n\r");
	//*(volatile u32 *)(0xA0180008) = 0;

	for(t=0;t<10;t++) {
		for(i=0;i<5;i++) {
			unsigned int j;
			for(j=0;j<8;j++) {
				u16 val;
				Generic_PhyRead(&mac_with_mdio, sgmiiphyaddr[i], j, &val);
				XFsbl_Printf(DEBUG_PRINT_ALWAYS,"[%d][%d][%d] 0x%04X\n\r", t, i, j, (u32)val);
			}
		}
		usleep(5000000);
		if(t==5) {
			u16 val;
			XFsbl_Printf(DEBUG_PRINT_ALWAYS,"Enabling loopback in pcs/pma\n\r");
			Generic_PhyRead(&mac_with_mdio, sgmiiphyaddr[0], 0, &val);
			Generic_PhyWrite(&mac_with_mdio, sgmiiphyaddr[0], 0, val|IEEE_CTRL_LOOPBACK_MASK);
                }
        }
	// Finally we need to disable the ISOLATE bit on all the SGMII cores
	// because it is enabled by default
	XFsbl_Printf(DEBUG_PRINT_ALWAYS,"96BQuadEthernet: Disable ISOLATE on all SGMII cores\n\r");

	// Configure the SGMII cores for ports 0-2
	// Auto-negotiation enable, full duplex, 1Gbps
	for(i=0; i<1; i++){
		Generic_PhyWrite(&mac_with_mdio, sgmiiphyaddr[i], PHY_CTRL_REG,
				IEEE_CTRL_DUPLEX_MASK | IEEE_CTRL_SPEED_MSB_MASK |
				IEEE_CTRL_AUTONEG_MASK);
		XFsbl_Printf(DEBUG_PRINT_ALWAYS,"Auto-negotiation enable\n\r");
	}
	// Configure the SGMII cores for port 3
	// No auto-negotiation, full duplex, 1Gbps
	for(i=1; i<5; i++){
		Generic_PhyWrite(&mac_with_mdio, sgmiiphyaddr[i], PHY_CTRL_REG,
				IEEE_CTRL_DUPLEX_MASK | IEEE_CTRL_SPEED_MSB_MASK |
				IEEE_CTRL_UNIDIRECTIONAL_MASK);
		XFsbl_Printf(DEBUG_PRINT_ALWAYS,"No auto-negotiation, full duplex, 1Gbps\n\r");
	}
#endif
#if 0
	// Initialize all 4x TI DP83867 PHYs
	for(i = 0; i<4; i++){
		init_dp83867_phy(&mac_with_mdio,extphyaddr[i]);
		XFsbl_Printf(DEBUG_PRINT_ALWAYS,"init_dp83867_phy\n\r");
	}

	// Disable SGMII auto-negotiation in the external PHY of port 3
	Generic_PhyRead(&mac_with_mdio, extphyaddr[3], TI_PHY_CFGR2, &control);
	control &= ~TI_PHY_CFG2_SGMII_AUTONEGEN;
	Generic_PhyWrite(&mac_with_mdio, extphyaddr[3], TI_PHY_CFGR2, control);
	XFsbl_Printf(DEBUG_PRINT_ALWAYS,"Complete.\n\r");
#endif
	return Status;
}

/*****************************************************************************/
/**
 * This is a hook function where user can include the functionality to be run
 * before FSBL fallback happens
 *
 * @param none
 *
 * @return error status based on implemented functionality (SUCCESS by default)
 *
  *****************************************************************************/

u32 XFsbl_HookBeforeFallback(void)
{
	u32 Status = XFSBL_SUCCESS;

	/**
	 * Add the code here
	 */

	return Status;
}

/*****************************************************************************/
/**
 * This function facilitates users to define different variants of psu_init()
 * functions based on different configurations in Vivado. The default call to
 * psu_init() can then be swapped with the alternate variant based on the
 * requirement.
 *
 * @param none
 *
 * @return error status based on implemented functionality (SUCCESS by default)
 *
  *****************************************************************************/

u32 XFsbl_HookPsuInit(void)
{
	u32 Status;
#ifdef XFSBL_ENABLE_DDR_SR
	u32 RegVal;
#endif

	/* Add the code here */

#ifdef XFSBL_ENABLE_DDR_SR
	/* Check if DDR is in self refresh mode */
	RegVal = Xil_In32(XFSBL_DDR_STATUS_REGISTER_OFFSET) &
		DDR_STATUS_FLAG_MASK;
	if (RegVal) {
		Status = (u32)psu_init_ddr_self_refresh();
	} else {
		Status = (u32)psu_init();
	}
#else
	Status = (u32)psu_init();
#endif

	if (XFSBL_SUCCESS != Status) {
			XFsbl_Printf(DEBUG_GENERAL,"XFSBL_PSU_INIT_FAILED\n\r");
			/**
			 * Need to check a way to communicate both FSBL code
			 * and PSU init error code
			 */
			Status = XFSBL_PSU_INIT_FAILED + Status;
	}

	/**
	 * PS_SYSMON_ANALOG_BUS register determines mapping between SysMon supply
	 * sense channel to SysMon supply registers inside the IP. This register
	 * must be programmed to complete SysMon IP configuration.
	 * The default register configuration after power-up is incorrect.
	 * Hence, fix this by writing the correct value - 0x3210.
	 */

	XFsbl_Out32(AMS_PS_SYSMON_ANALOG_BUS, PS_SYSMON_ANALOG_BUS_VAL);

	return Status;
}

/*****************************************************************************/
/**
 * This function detects type of boot based on information from
 * PMU_GLOBAL_GLOB_GEN_STORAGE1. If Power Off Suspend is supported FSBL must
 * wait for PMU to detect boot type and provide that information using register.
 * In case of resume from Power Off Suspend PMU will wait for FSBL to confirm
 * detection by writing 1 to PMU_GLOBAL_GLOB_GEN_STORAGE2.
 *
 * @return Boot type, 0 in case of cold boot, 1 for warm boot
 *
 * @note none
 *****************************************************************************/
#ifdef ENABLE_POS
u32 XFsbl_HookGetPosBootType(void)
{
	u32 WarmBoot = 0;
	u32 RegValue = 0;

	do {
		RegValue = XFsbl_In32(PMU_GLOBAL_GLOB_GEN_STORAGE1);
	} while (0U == RegValue);

	/* Clear Gen Storage register so it can be used later in system */
	XFsbl_Out32(PMU_GLOBAL_GLOB_GEN_STORAGE1, 0U);

	WarmBoot = RegValue - 1;

	/* Confirm detection in case of resume from Power Off Suspend */
	if (0 != RegValue) {
		XFsbl_Out32(PMU_GLOBAL_GLOB_GEN_STORAGE2, 1U);
	}

	return WarmBoot;
}
#endif
