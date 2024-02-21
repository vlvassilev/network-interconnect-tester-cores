# test_my_design.py (simple)

import cocotb
from cocotb.triggers import Timer

CLK_PERIOD_NS = 8
AXI_CLK_PERIOD_NS = 10

@cocotb.test()
async def my_first_test(dut):
    """Try accessing the design."""

    for cycle in range(1000):
        dut.clk.value = 0
        await Timer(CLK_PERIOD_NS/2, units="ns")
        dut.clk.value = 1
        await Timer(CLK_PERIOD_NS/2, units="ns")
        if(cycle<500):
            dut.resetn.value=0
        else:
            dut.resetn.value=1


    dut._log.info("sec is %s", dut.sec.value)
    dut._log.info("nsec is %s", dut.nsec.value)
    dut._log.info("cycle is %s", cycle)
    assert int(dut.sec.value) == 0, "nsec is not right!"
    assert int(dut.nsec.value)/8 == (int(cycle)-500), "nsec is not right!"




# test_my_design.py (extended)

import cocotb
from cocotb.triggers import FallingEdge, Timer

async def generate_clock(dut):
    """Generate clock pulses."""

    for cycle in range(1000):
        dut.clk.value = 0
        await Timer(CLK_PERIOD_NS/2, units="ns")
        dut.clk.value = 1
        await Timer(CLK_PERIOD_NS/2, units="ns")

@cocotb.test()
async def my_second_test(dut):
    """Try accessing the design."""

    await cocotb.start(generate_clock(dut))  # run the clock "in the background"



    dut.resetn.value=0
    await Timer(500*CLK_PERIOD_NS, units="ns")  # wait a bit
    dut.resetn.value=1

    await Timer(500*CLK_PERIOD_NS-8, units="ns")  # wait a bit
    cycle=999

    dut._log.info("sec is %s", dut.sec.value)
    dut._log.info("nsec is %s", dut.nsec.value)
    assert int(dut.sec.value) == 0, "nsec is not right!"
    assert int(dut.nsec.value)/8 == (int(cycle)-500), "nsec is not right!"
