`timescale 1ns/1ps
`include "traffic_generator_gmii_cpu_regs_defines.v"
`include "traffic_analyzer_gmii_cpu_regs_defines.v"
`include "rtclock_cpu_regs_defines.v"
module tb;

localparam CLK_PERIOD_NS=8;

localparam AXI_CLK_PERIOD_NS=10;
localparam C_S_AXI_DATA_WIDTH =  32;
localparam C_S_AXI_ADDR_WIDTH =  32;
localparam TG_BASEADDR =   32'h10000000;
localparam TA_BASEADDR =    32'h20000000;
localparam RC_BASEADDR =    32'h30000000;


reg clk;
reg rst;
reg pps;
reg pps2;

wire [47:0] sec;
wire [29:0] nsec;
time       cur_time;

wire [8 - 1:0] gmii_d;
wire gmii_en;
wire gmii_er;

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

reg [31:0] data;
reg [63:0] data64;
reg [7:0] frame [0:1530];
reg [63:0] sec_config;
integer i;
integer len;

//{16'{1'b0},

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

always @(negedge S_AXI_ACLK) begin
//    $display("axi time=%t, S_AXI_RDATA=%x sec=%x, nsec=%x", $time, S_AXI_RDATA, sec, nsec);
end

initial begin
    clk = 1;
    rst = 0;
    pps = 0;
    pps2 = 0;
    sec_config=123;

    S_AXI_ARESETN=1;
    S_AXI_ACLK = 1;

    #(10*CLK_PERIOD_NS) rst = 1;

    #(10*CLK_PERIOD_NS) rst = 0;

    #(10*CLK_PERIOD_NS) S_AXI_ARESETN=0;

    #(10*CLK_PERIOD_NS) S_AXI_ARESETN=1;

    #(100*CLK_PERIOD_NS)
    axi_write(RC_BASEADDR+`REG_SEC_CONFIG_ADDR, sec_config[63:32]);
    axi_write(RC_BASEADDR+`REG_SEC_CONFIG_ADDR+4, sec_config[31:0]);
    axi_write(RC_BASEADDR+`REG_CONTROL_ADDR, 1);

    #(10*CLK_PERIOD_NS)
    pps = 1;
    pps2 = 1;

    $display("nsec=%d",nsec);
    #(8*84*50*CLK_PERIOD_NS)

    $display("nsec=%d",nsec);

    #(8*84*CLK_PERIOD_NS)

    axi_read(RC_BASEADDR+`REG_SEC_STATE_ADDR, data64[63:32]);
    axi_read(RC_BASEADDR+`REG_SEC_STATE_ADDR+4, data64[31:0]);
    $display("rtclock axi sec=%d", data64);
    if(data64 != sec_config+1) begin
        $error("Read incorrect rtclock.sec_state over AXI instead of (%d)", sec_config+1, data64);
        $fatal;
    end

    //wait (sec[3]);

    $finish;

end

endmodule
