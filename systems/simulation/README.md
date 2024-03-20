# Pre-silicon simulation of the YANG model implementation

You can use a cocotb/iverilog simulation of a single *traffic_generator_gmii* connected to a single *traffic_analyzer_gmii* and a common *rtclock* cores.

```
     eth0          NETCONF Server (YANG Model)    eth1

 TRAFFIC-GENERATOR (SW)               TRAFFIC-ANALYZER (SW)
     |                                    |
 Socket API                           Socket API
     |                   (GMII)           |
  TRAFFIC-GENERATOR (HW) ------ TRAFFIC-ANALYZER (HW)
                       \       /
                        \     /
                        RTCLOCK
```

The cocotb simulation after initialization and reset of the design instantiated in [tester_loop.v](tester_loop.v) listens on a socket accepting register *read*, *write*, and simulation *run* and *finish* commands.

Build the software under network-interconnect-tester/lib/sw/lsi as follows:

```
autoreconf -i -f
./configure CFLAGS="-g -O0"  CXXFLAGS="-g -O0" --prefix=/usr --enable-simulation
make
sudo make install
```


Start a simulation in this directory with the [run.sh](run.sh) wrapper script that invokes a cocotb python simulation environment
that accept register read and write accesses from user applications over socket and can run the simulation with the help
of the sim-run and sim-finish commands:

Install cocotbext-axi:
```
git clone https://github.com/alexforencich/cocotbext-axi
pip install -e cocotbext-axi
```

```
./run.sh
```


In a new terminal start a netconfd server with the model implementation:
```
netconfd --superuser=y123 --module=ietf-traffic-generator --module=ietf-traffic-analyzer --no-startup
```

Now you can connect to the netconfd server with any application and the simulated hardware will be used as if you had a real target.

You can use either [yangcli](https://packages.debian.org/sid/yangcli) to configure the traffic generator and monitor the traffic analyzer. You can use the [rfc2544-benchmark](https://github.com/lightside-instruments/rfc2544-benchmark) script or any other application.

Keep in mind that you need to call *sim-run* e.g. `sim-run 1000 ns` command to progress the simulation environment after the transactions performing AXI
read and write operations.

One option is to start a new terminal with the `sim-run` script executed in a loop or for a more precise option call the command instead of delays in the test applications.

