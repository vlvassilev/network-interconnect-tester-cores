`timescale 1ns/1ps

module tester_loop       #(
           parameter C_S_AXI_DATA_WIDTH    = 32,
           parameter C_S_AXI_ADDR_WIDTH    = 32,
           parameter C_CLK_TO_NS_RATIO    = 8

       )
(
    input clk,
    input resetn,
    input pps,
    input pps2,

    output reg [47:0] sec,
    output reg [29:0] nsec,

    // Slave AXI Ports
    input                                     S_AXI_ACLK,
    input                                     S_AXI_ARESETN,
    input      [C_S_AXI_ADDR_WIDTH-1 : 0]     S_AXI_AWADDR,
    input                                     S_AXI_AWVALID,
    input      [C_S_AXI_DATA_WIDTH-1 : 0]     S_AXI_WDATA,
    input      [C_S_AXI_DATA_WIDTH/8-1 : 0]   S_AXI_WSTRB,
    input                                     S_AXI_WVALID,
    input                                     S_AXI_BREADY,
    input      [C_S_AXI_ADDR_WIDTH-1 : 0]     S_AXI_ARADDR,
    input                                     S_AXI_ARVALID,
    input                                     S_AXI_RREADY,
    output                                    S_AXI_ARREADY,
    output     [C_S_AXI_DATA_WIDTH-1 : 0]     S_AXI_RDATA,
    output     [1 : 0]                        S_AXI_RRESP,
    output                                    S_AXI_RVALID,
    output                                    S_AXI_WREADY,
    output     [1 :0]                         S_AXI_BRESP,
    output                                    S_AXI_BVALID,
    output                                    S_AXI_AWREADY,

    // Slave AXI Ports TG
    input                                     S_AXI_TG_ACLK,
    input                                     S_AXI_TG_ARESETN,
    input      [C_S_AXI_ADDR_WIDTH-1 : 0]     S_AXI_TG_AWADDR,
    input                                     S_AXI_TG_AWVALID,
    input      [C_S_AXI_DATA_WIDTH-1 : 0]     S_AXI_TG_WDATA,
    input      [C_S_AXI_DATA_WIDTH/8-1 : 0]   S_AXI_TG_WSTRB,
    input                                     S_AXI_TG_WVALID,
    input                                     S_AXI_TG_BREADY,
    input      [C_S_AXI_ADDR_WIDTH-1 : 0]     S_AXI_TG_ARADDR,
    input                                     S_AXI_TG_ARVALID,
    input                                     S_AXI_TG_RREADY,
    output                                    S_AXI_TG_ARREADY,
    output     [C_S_AXI_DATA_WIDTH-1 : 0]     S_AXI_TG_RDATA,
    output     [1 : 0]                        S_AXI_TG_RRESP,
    output                                    S_AXI_TG_RVALID,
    output                                    S_AXI_TG_WREADY,
    output     [1 :0]                         S_AXI_TG_BRESP,
    output                                    S_AXI_TG_BVALID,
    output                                    S_AXI_TG_AWREADY,


    // Slave AXI Ports TA
    input                                     S_AXI_TA_ACLK,
    input                                     S_AXI_TA_ARESETN,
    input      [C_S_AXI_ADDR_WIDTH-1 : 0]     S_AXI_TA_AWADDR,
    input                                     S_AXI_TA_AWVALID,
    input      [C_S_AXI_DATA_WIDTH-1 : 0]     S_AXI_TA_WDATA,
    input      [C_S_AXI_DATA_WIDTH/8-1 : 0]   S_AXI_TA_WSTRB,
    input                                     S_AXI_TA_WVALID,
    input                                     S_AXI_TA_BREADY,
    input      [C_S_AXI_ADDR_WIDTH-1 : 0]     S_AXI_TA_ARADDR,
    input                                     S_AXI_TA_ARVALID,
    input                                     S_AXI_TA_RREADY,
    output                                    S_AXI_TA_ARREADY,
    output     [C_S_AXI_DATA_WIDTH-1 : 0]     S_AXI_TA_RDATA,
    output     [1 : 0]                        S_AXI_TA_RRESP,
    output                                    S_AXI_TA_RVALID,
    output                                    S_AXI_TA_WREADY,
    output     [1 :0]                         S_AXI_TA_BRESP,
    output                                    S_AXI_TA_BVALID,
    output                                    S_AXI_TA_AWREADY

);



localparam CLK_PERIOD_NS=8;

localparam AXI_CLK_PERIOD_NS=10;
localparam RC_BASEADDR = 32'h00000000;
localparam TG_BASEADDR = 32'h10000000;
localparam TA_BASEADDR = 32'h20000000;


wire clk_;
wire resetn_;
wire [47:0] sec_;
wire [29:0] nsec_;
time       cur_time;

wire [8 - 1:0] gmii_d;
wire gmii_en;
wire gmii_er;


reg [31:0] data;
reg [63:0] data64;
reg [7:0] frame [0:1530];
integer i;
integer len;

assign sec = sec_;
assign nsec = nsec_;
assign clk_ = clk;
assign resetn_ = resetn;

rtclock #(
           .C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
           .C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH),
           .C_BASEADDR(RC_BASEADDR),
           .C_CLK_TO_NS_RATIO(CLK_PERIOD_NS)
         ) rtclock0 (
                           .clk(clk_),
                           .resetn(resetn_),
                           .sec(sec_),
                           .nsec(nsec_),
                           .pps(pps),
                           .pps2(pps2),

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

traffic_generator_gmii #(
           .C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
           .C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH),
           .C_BASEADDR(TG_BASEADDR),
           .C_CLK_TO_NS_RATIO(CLK_PERIOD_NS)
                       ) traffic_generator_gmii0
                       (
                           .clk(clk),
                           .resetn(resetn_),

                           .gmii_d(gmii_d),
                           .gmii_en(gmii_en),
                           .gmii_er(gmii_er),

                           .sec(sec_),
                           .nsec(nsec_),


                           // AXI Lite ports
                           .S_AXI_ACLK(S_AXI_TG_ACLK),
                           .S_AXI_ARESETN(S_AXI_TG_ARESETN),
                           .S_AXI_AWADDR(S_AXI_TG_AWADDR),
                           .S_AXI_AWVALID(S_AXI_TG_AWVALID),
                           .S_AXI_WDATA(S_AXI_TG_WDATA),
                           .S_AXI_WSTRB(S_AXI_TG_WSTRB),
                           .S_AXI_WVALID(S_AXI_TG_WVALID),
                           .S_AXI_BREADY(S_AXI_TG_BREADY),
                           .S_AXI_ARADDR(S_AXI_TG_ARADDR),
                           .S_AXI_ARVALID(S_AXI_TG_ARVALID),
                           .S_AXI_RREADY(S_AXI_TG_RREADY),
                           .S_AXI_ARREADY(S_AXI_TG_ARREADY),
                           .S_AXI_RDATA(S_AXI_TG_RDATA),
                           .S_AXI_RRESP(S_AXI_TG_RRESP),
                           .S_AXI_RVALID(S_AXI_TG_RVALID),
                           .S_AXI_WREADY(S_AXI_TG_WREADY),
                           .S_AXI_BRESP(S_AXI_TG_BRESP),
                           .S_AXI_BVALID(S_AXI_TG_BVALID),
                           .S_AXI_AWREADY(S_AXI_TG_AWREADY)


                       );

traffic_analyzer_gmii #(
           .C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
           .C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH),
           .C_BASEADDR(TA_BASEADDR),
           .C_CLK_TO_NS_RATIO(CLK_PERIOD_NS)
                      ) traffic_analyzer_gmii0
                      (
                          .clk(clk_),
                          .resetn(resetn_),

                          .gmii_d(gmii_d),
                          .gmii_en(gmii_en),
                          .gmii_er(gmii_er),

                          .sec(sec_),
                          .nsec(nsec_),

                          // AXI Lite ports
                          .S_AXI_ACLK(S_AXI_TA_ACLK),
                          .S_AXI_ARESETN(S_AXI_TA_ARESETN),
                          .S_AXI_AWADDR(S_AXI_TA_AWADDR),
                          .S_AXI_AWVALID(S_AXI_TA_AWVALID),
                          .S_AXI_WDATA(S_AXI_TA_WDATA),
                          .S_AXI_WSTRB(S_AXI_TA_WSTRB),
                          .S_AXI_WVALID(S_AXI_TA_WVALID),
                          .S_AXI_BREADY(S_AXI_TA_BREADY),
                          .S_AXI_ARADDR(S_AXI_TA_ARADDR),
                          .S_AXI_ARVALID(S_AXI_TA_ARVALID),
                          .S_AXI_RREADY(S_AXI_TA_RREADY),
                          .S_AXI_ARREADY(S_AXI_TA_ARREADY),
                          .S_AXI_RDATA(S_AXI_TA_RDATA),
                          .S_AXI_RRESP(S_AXI_TA_RRESP),
                          .S_AXI_RVALID(S_AXI_TA_RVALID),
                          .S_AXI_WREADY(S_AXI_TA_WREADY),
                          .S_AXI_BRESP(S_AXI_TA_BRESP),
                          .S_AXI_BVALID(S_AXI_TA_BVALID),
                          .S_AXI_AWREADY(S_AXI_TA_AWREADY)
                      );

endmodule
