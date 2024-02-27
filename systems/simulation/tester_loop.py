import cocotb
from cocotb.triggers import FallingEdge, Timer
from cocotbext.axi import AxiLiteMaster, AxiLiteBus

import subprocess
import socket

CLK_PERIOD_NS = 8
AXI_CLK_PERIOD_NS = 10

REG_FLIP_ADDR = 0x0000000C
REG_CONTROL_ADDR =  0x00000010
REG_INTERFRAME_GAP_ADDR =  0x00000014
REG_FRAME_SIZE_ADDR = 0x00000044
REG_FRAME_BUF_ADDR = 0x00000050

REG_PKTS_ADDR = 0x00000020

axi_master_rc = None
axi_master_tg = None
axi_master_ta = None

def axi_offset_from_address(address):
    return address & 0x0FFFFFFF

def axi_handle_from_address(address):
    global axi_master_rc
    global axi_master_tg
    global axi_master_ta

    if(address < 0x10000000):
        return axi_master_rc
    elif(address < 0x20000000):
        return axi_master_tg
    elif(address < 0x30000000):
        return axi_master_ta
    else:
        print("invalid address=0x%08X"%address)
        return None

async def get_state(state_filename):
    global axi_master_tg
    global axi_master_ta

    # in dynamic mode 8 bytes sequence number and 10 octets 1588 timestamp are added to the end of the static frame data 4 bytes CRC
    data = await axi_master_ta.read(REG_PKTS_ADDR, 4)

async def set_config2(cfg_filename):
    global axi_master_tg
    global axi_master_ta

    p = subprocess.Popen("./config2regs %s"%cfg_filename, stdout=subprocess.PIPE, shell=True)
    (output, err) = p.communicate()
    p_status = p.wait()
    print(output)
    for line in output.splitlines():
        print(line)
        args=line.decode().split()
        print(args)
        addr=int(args[0],16)
        data=int(args[1],16)
        await axi_master_tg.write(addr, int(data).to_bytes(4, 'big') )

async def set_config(cfg_filename):
    global axi_master_tg
    global axi_master_ta

    print(axi_master_tg)
    # in dynamic mode 8 bytes sequence number and 10 octets 1588 timestamp are added to the end of the static frame data 4 bytes CRC
    await axi_master_tg.write(REG_INTERFRAME_GAP_ADDR, int(20).to_bytes(4, 'little') )

#    fh = open("frame.mem", mode='rb') # frame includes layer1 preamble 55555555555555d5...
#    frame = bytearray(fh.read())

    fh = open("frame.mem", mode='r')
    frame = bytearray()
    for line in fh.readlines():
        frame.extend(bytearray.fromhex(line))

    print(frame)
    await axi_master_tg.write(REG_FRAME_SIZE_ADDR, int(len(frame)).to_bytes(4, 'little') )

    for i in range(int(len(frame)/4)):
        await axi_master_tg.write(REG_FRAME_BUF_ADDR, frame[i*4:i*4+4])

    await axi_master_tg.write(REG_CONTROL_ADDR, int(3).to_bytes(4, 'little') )


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

async def generate_clock_axi_tg(dut):
    """Generate clock pulses."""

    while(True):
        dut.S_AXI_TG_ACLK.value = 1
        await Timer(AXI_CLK_PERIOD_NS/2, units="ns")
        dut.S_AXI_TG_ACLK.value = 0
        await Timer(AXI_CLK_PERIOD_NS/2, units="ns")

async def generate_clock_axi_ta(dut):
    """Generate clock pulses."""

    while(True):
        dut.S_AXI_TA_ACLK.value = 1
        await Timer(AXI_CLK_PERIOD_NS/2, units="ns")
        dut.S_AXI_TA_ACLK.value = 0
        await Timer(AXI_CLK_PERIOD_NS/2, units="ns")

@cocotb.test()
async def flip_register(dut):

    global axi_master_rc
    global axi_master_tg
    global axi_master_ta

    await cocotb.start(generate_clock(dut))  # controls dut.clk.value, runs the clock "in the background"
    await cocotb.start(generate_clock_axi(dut))  # controls dut.S_AXI_ACLK.value, run the AXI clock "in the background"
    await cocotb.start(generate_clock_axi_tg(dut))  # controls dut.S_AXI_TG_ACLK.value, run the AXI clock "in the background"
    await cocotb.start(generate_clock_axi_ta(dut))  # controls dut.S_AXI_TA_ACLK.value, run the AXI clock "in the background"

    dut.pps.value = 0
    dut.pps2.value = 0
    dut.resetn.value=1
    dut.S_AXI_ARESETN.value=1
    dut.S_AXI_TG_ARESETN.value=1
    dut.S_AXI_TA_ARESETN.value=1




    await Timer(2*CLK_PERIOD_NS, units="ns")  # wait a bit
    dut.resetn.value=0
    await Timer(2*CLK_PERIOD_NS, units="ns")  # wait a bit
    dut.resetn.value=1

    await Timer(2*CLK_PERIOD_NS, units="ns")  # wait a bit
    dut.S_AXI_ARESETN.value=0
    dut.S_AXI_TG_ARESETN.value=0
    dut.S_AXI_TA_ARESETN.value=0
    await Timer(2*CLK_PERIOD_NS, units="ns")  # wait a bit
    dut.S_AXI_ARESETN.value=1
    dut.S_AXI_TG_ARESETN.value=1
    dut.S_AXI_TA_ARESETN.value=1


    await Timer(2*CLK_PERIOD_NS, units="ns")  # wait a bit

    axi_master_rc = AxiLiteMaster(AxiLiteBus.from_prefix(dut, "S_AXI"),dut.S_AXI_ACLK, dut.S_AXI_ARESETN, reset_active_level=False)
    axi_master_tg = AxiLiteMaster(AxiLiteBus.from_prefix(dut, "S_AXI_TG"),dut.S_AXI_TG_ACLK, dut.S_AXI_TG_ARESETN, reset_active_level=False)
    axi_master_ta = AxiLiteMaster(AxiLiteBus.from_prefix(dut, "S_AXI_TA"),dut.S_AXI_TA_ACLK, dut.S_AXI_TA_ARESETN, reset_active_level=False)

    await axi_master_rc.write(REG_FLIP_ADDR, int(0x12345678).to_bytes(4, 'big') )

    data = await axi_master_rc.read(REG_FLIP_ADDR, 4)

    flip32 = int.from_bytes(data.data, byteorder='big', signed = False)
    assert flip32 == (int(0x12345678) ^ 0xFFFFFFFF), "ERROR. Current value at REG_FLIP_ADDR equals 0x%08X  which is not the expected 0x%08X"%(flip32,(int(0x12345678) ^ 0xFFFFFFFF))
    print("OK. Current value at REG_FLIP_ADDR is 0x%08X as expected"%(flip32))


    # open simulation control socket
    server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    server.bind("/tmp/simulation")

    # start control script

    # handle commands - write, read, wait, finish
    # write 0x12345678 0x12345678
    # read 0x12345678
    # run 1000 ns
 
    print("Listening ...")
    server.listen(1)
    while(1):
        print("Accepting ...")
        state="continue"
        conn, addr = server.accept()
        while(1):
            print("Receiving ...")
            try:
                cmd = conn.recv(1024).decode()
            except socket.error as e: 
                assert True, "Error receiving data: %s" % (e)
                break

            print("Received: %s"%(cmd))
            if(cmd.startswith("finish")):
                state="finish"
                conn.send("ok\n".encode('utf-8'))
                conn.close()
                break
            elif(cmd.startswith("run ")):
                args = cmd.split()
                await Timer(int(args[1]), units=args[2])
                conn.send("ok\n".encode('utf-8'))

            elif(cmd.startswith("read ")):
                args = cmd.split()
                address = int(args[1],16)
                axi_master = axi_handle_from_address(address)
                offset = axi_offset_from_address(address)
                data = await axi_master.read(address, 4)
                print("Read complete. Sending reply ...")

                conn.send(("0x%08X\n"%int.from_bytes(data.data, byteorder='little', signed = False)).encode('utf-8'))
                print("Reply sent.")

            elif(cmd.startswith("write ")):
                args = cmd.split()
                address = int(args[1],16)
                axi_master = axi_handle_from_address(address)
                offset = axi_offset_from_address(address)
                print("address=0x%08X, offset=0x%08X"%(address, offset))
                await axi_master.write(address, int(args[2],16).to_bytes(4, 'little'))
                conn.send("ok\n".encode('utf-8'))

            else:
                break
#                assert False "Invalid command"
        if(state!="continue"):
            server.close()
            break


#    await set_config2("config-1.xml")

#    await Timer(500*CLK_PERIOD_NS, units="ns")  # wait a bit

#    await get_state("state-1.xml")

