import cocotb
from cocotb.triggers import FallingEdge, Timer
from cocotbext.axi import AxiLiteMaster, AxiLiteBus


CLK_PERIOD_NS = 8
AXI_CLK_PERIOD_NS = 10
REG_FLIP_ADDR = 0x0000000C

async def generate_clock(dut):
    """Generate clock pulses."""

    while(True):
        dut.clk.value = 1
        await Timer(CLK_PERIOD_NS/2, units="ns")
        dut.clk.value = 0
        await Timer(CLK_PERIOD_NS/2, units="ns")

async def generate_clock_axi(dut):
    """Generate clock pulses."""

    while(True):
        dut.S_AXI_ACLK.value = 1
        await Timer(AXI_CLK_PERIOD_NS/2, units="ns")
        dut.S_AXI_ACLK.value = 0
        await Timer(AXI_CLK_PERIOD_NS/2, units="ns")

@cocotb.test()
async def flip_register(dut):



    await cocotb.start(generate_clock(dut))  # controls dut.clk.value, runs the clock "in the background"
    await cocotb.start(generate_clock_axi(dut))  # controls dut.S_AXI_ACLK.value, run the AXI clock "in the background"

    dut.pps.value = 0
    dut.pps2.value = 0
    dut.resetn.value=1
    dut.S_AXI_ARESETN.value=1




    await Timer(2*CLK_PERIOD_NS, units="ns")  # wait a bit
    dut.resetn.value=0
    await Timer(2*CLK_PERIOD_NS, units="ns")  # wait a bit
    dut.resetn.value=1

    await Timer(2*CLK_PERIOD_NS, units="ns")  # wait a bit
    dut.S_AXI_ARESETN.value=0
    await Timer(2*CLK_PERIOD_NS, units="ns")  # wait a bit
    dut.S_AXI_ARESETN.value=1


    await Timer(2*CLK_PERIOD_NS, units="ns")  # wait a bit

    axi_master = AxiLiteMaster(AxiLiteBus.from_prefix(dut, "S_AXI"),dut.S_AXI_ACLK, dut.S_AXI_ARESETN, reset_active_level=False)

    await axi_master.write(REG_FLIP_ADDR, int(0x12345678).to_bytes(4, 'big') )

    data = await axi_master.read(REG_FLIP_ADDR, 4)

    flip32 = int.from_bytes(data.data, byteorder='big', signed = False)
    assert flip32 == (int(0x12345678) ^ 0xFFFFFFFF), "ERROR. Current value at REG_FLIP_ADDR equals 0x%08X  which is not the expected 0x%08X"%(flip32,(int(0x12345678) ^ 0xFFFFFFFF))
    print("OK. Current value at REG_FLIP_ADDR is 0x%08X as expected"%(flip32))
