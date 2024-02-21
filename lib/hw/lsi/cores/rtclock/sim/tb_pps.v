`timescale 1ns/1ps
`include "rtclock_cpu_regs_defines.v"

module tb_pps;

  //localparam CLK_PERIOD_NS=110000000;
  localparam CLK_PERIOD_NS=8;

  localparam AXI_CLK_PERIOD_NS=10;
  localparam C_S_AXI_DATA_WIDTH =  32;
  localparam C_S_AXI_ADDR_WIDTH =  32;
  localparam RC_BASEADDR =    32'h30000000;

  reg clk;
  reg rst;
  wire [47:0] sec;
  wire [29:0] nsec;
  reg pps;
  reg pps2;
  reg [63:0] data64;
  reg [31:0] data;

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


  time       cur_time;



  rtclock #(.C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
           .C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH),
           .C_BASEADDR(RC_BASEADDR),
           .C_CLK_TO_NS_RATIO(CLK_PERIOD_NS) ) rtclock0 (.clk(clk), .resetn(~rst), .sec(sec), .nsec(nsec), .pps(pps), .pps2(pps2),
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


  always @(posedge clk) begin
           cur_time = $time;
//           $display("time=%t sec=%d,  nsec=%d, rst=%d, pps2=%d", cur_time, sec, nsec, rst, pps2);
//           if($time != 0 & $time != (sec*1000000000 + nsec + 2*CLK_PERIOD_NS)) begin
//               $error("Error time=%t != %d", $time, (sec*1000000000 + nsec + 2*CLK_PERIOD_NS));
//               $fatal;
//           end
  end

  initial begin

     $dumpfile("tb-axi-lite-read-write.vcd");
     $dumpvars;
//     $dumpvars(0, tb_axi_lite_read_write);

     clk = 1;
     rst = 0;
     pps = 0;
     pps2 = 0;

     S_AXI_ARESETN=1;
     S_AXI_ACLK = 1;

     #(10*CLK_PERIOD_NS) rst = 1;

     #(10*CLK_PERIOD_NS) rst = 0;


     #(10*CLK_PERIOD_NS) S_AXI_ARESETN=0;


     #(10*CLK_PERIOD_NS) S_AXI_ARESETN=1;



     #(100*CLK_PERIOD_NS)
     //wait (sec[2]);


     axi_read(RC_BASEADDR+`REG_SEC_STATE_ADDR, data64[63:32]);
     axi_read(RC_BASEADDR+`REG_SEC_STATE_ADDR+4, data64[31:0]);
     $display("rtclock axi sec=%d", data64);

     axi_write(RC_BASEADDR+`REG_SEC_CONFIG_ADDR, 32'd0);
     axi_write(RC_BASEADDR+`REG_SEC_CONFIG_ADDR+4, 32'd10);
     axi_write(RC_BASEADDR+`REG_CONTROL_ADDR, 3); //Enable PPS, Select PPS (PPS2)


     #(10*CLK_PERIOD_NS)
     pps2 = 1;
     #(10*CLK_PERIOD_NS)
     pps2 = 0;

     #(100*CLK_PERIOD_NS)


     axi_read(RC_BASEADDR+`REG_SEC_STATE_ADDR, data64[63:32]);
     axi_read(RC_BASEADDR+`REG_SEC_STATE_ADDR+4, data64[31:0]);
     $display("rtclock axi sec=%d", data64);
     if (data64==10) $display("OK. Current value of REG_SEC_STATE_ADDR  equals 10");
     else begin
         $error("ERROR. Current value at REG_SEC_STATE_ADDR(0,+4)  equals %d instead of 10", data64);
         $fatal;
     end
     $finish;

  end

endmodule

