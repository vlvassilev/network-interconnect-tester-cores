`timescale 1ns/1ps
`include "rtclock_cpu_regs_defines.v"

module flip_register;

  //localparam CLK_PERIOD_NS=110000000;
  localparam CLK_PERIOD_NS=8;

  localparam AXI_CLK_PERIOD_NS=10;
  localparam C_S_AXI_DATA_WIDTH =  32;
  localparam C_S_AXI_ADDR_WIDTH =  32;
  localparam RC_BASEADDR =    32'h00000000;

  reg clk;
  reg resetn;
  wire [47:0] sec;
  wire [29:0] nsec;
  reg pps;
  reg pps2;
  reg [31:0] data_r;
  reg [31:0] data_w;

// AXI Lite ports
reg                                S_AXI_ACLK; /* inputs */
reg                                S_AXI_ARESETN;
reg [C_S_AXI_ADDR_WIDTH-1 : 0]     S_AXI_AWADDR;
reg                                S_AXI_AWVALID;
reg [C_S_AXI_DATA_WIDTH-1 : 0]     S_AXI_WDATA;
reg [C_S_AXI_DATA_WIDTH/8-1 : 0]   S_AXI_WSTRB;
reg                                S_AXI_WVALID;
reg                                S_AXI_BREADY;
reg [C_S_AXI_ADDR_WIDTH-1 : 0]     S_AXI_ARADDR;
reg                                S_AXI_ARVALID;
reg                                S_AXI_RREADY;
wire                               S_AXI_ARREADY; /* outputs */
wire [C_S_AXI_DATA_WIDTH-1 : 0]    S_AXI_RDATA;
wire [1 : 0]                       S_AXI_RRESP;
wire                               S_AXI_RVALID;
wire                               S_AXI_WREADY;
wire [1 :0]                        S_AXI_BRESP;
wire                               S_AXI_BVALID;
wire                               S_AXI_AWREADY;



  rtclock #(.C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
           .C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH),
           .C_BASEADDR(RC_BASEADDR),
           .C_CLK_TO_NS_RATIO(CLK_PERIOD_NS) ) rtclock0 (.clk(clk), .resetn(resetn), .sec(sec), .nsec(nsec), .pps(pps), .pps2(pps2),
                           // AXI Lite ports
                           .S_AXI_ACLK(S_AXI_ACLK),
                           .S_AXI_ARESETN(S_AXI_ARESETN),
                           .S_AXI_AWADDR(S_AXI_AWADDR),
                           .S_AXI_AWVALID(S_AXI_AWVALID),
                           .S_AXI_WDATA(S_AXI_WDATA),
                           .S_AXI_WSTRB(S_AXI_WSTRB),
                           .S_AXI_WVALID(S_AXI_WVALID),
                           .S_AXI_BREADY(S_AXI_BREADY),
                           .S_AXI_ARADDR(S_AXI_ARADDR),
                           .S_AXI_ARVALID(S_AXI_ARVALID),
                           .S_AXI_RREADY(S_AXI_RREADY),
                           .S_AXI_ARREADY(S_AXI_ARREADY),
                           .S_AXI_RDATA(S_AXI_RDATA),
                           .S_AXI_RRESP(S_AXI_RRESP),
                           .S_AXI_RVALID(S_AXI_RVALID),
                           .S_AXI_WREADY(S_AXI_WREADY),
                           .S_AXI_BRESP(S_AXI_BRESP),
                           .S_AXI_BVALID(S_AXI_BVALID),
                           .S_AXI_AWREADY(S_AXI_AWREADY)
);

`include "axi.v"

  always #(CLK_PERIOD_NS / 2) clk = ~clk;
  always #(AXI_CLK_PERIOD_NS / 2) S_AXI_ACLK = ~S_AXI_ACLK;



  initial begin

     $dumpfile("flip-register.vcd");
     $dumpvars;

     clk = 1;
     resetn = 1;
     pps = 0;
     pps2 = 0;
     S_AXI_ARESETN=1;
     S_AXI_ACLK = 1;

     #(2*CLK_PERIOD_NS) resetn = 0;

     #(2*CLK_PERIOD_NS) resetn = 1;


     #(2*CLK_PERIOD_NS) S_AXI_ARESETN=0;


     #(2*CLK_PERIOD_NS) S_AXI_ARESETN=1;



     #(2*CLK_PERIOD_NS)

     data_w = 32'h12345678;
     axi_write(RC_BASEADDR+`REG_FLIP_ADDR, data_w);

     axi_read(RC_BASEADDR+`REG_FLIP_ADDR, data_r[31:0]);

     if (data_r == ~data_w) $display("OK. Current value at REG_FLIP_ADDR is 0x%08X as expected", data_r);
     else begin
         $error("ERROR. Current value at REG_FLIP_ADDR equals 0x%08X  which is not the expected 0x%08X", data_r, ~data_w);
         $fatal;
     end
     $finish;

  end

endmodule
