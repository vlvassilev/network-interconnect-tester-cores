`timescale 1ns/1ps
`include "traffic_analyzer_gmii_cpu_regs_defines.v"
`include "traffic_generator_gmii_cpu_regs_defines.v"
module tb;

localparam CLK_PERIOD_NS=8;

localparam AXI_CLK_PERIOD_NS=10;
localparam C_S_AXI_DATA_WIDTH =  32;
localparam C_S_AXI_ADDR_WIDTH =  32;
localparam TG_BASEADDR =   32'h10000000;
localparam TA_BASEADDR =    32'h20000000;


reg clk;
reg rst;
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
integer i;
integer len;


rtclock #( CLK_PERIOD_NS ) rtclock0 (.clk(clk), .resetn(~rst), .sec(sec), .nsec(nsec));

traffic_generator_gmii #(
                           C_S_AXI_DATA_WIDTH,
                           C_S_AXI_ADDR_WIDTH,
                           TG_BASEADDR
                       ) traffic_generator_gmii0
                       (
                           .clk(clk),
                           .resetn(~rst),

                           .gmii_d(gmii_d),
                           .gmii_en(gmii_en),
                           .gmii_er(gmii_er),

                           .sec(sec),
                           .nsec(nsec),


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


traffic_analyzer_gmii #(
                          C_S_AXI_DATA_WIDTH,
                          C_S_AXI_ADDR_WIDTH,
                          TA_BASEADDR
                      ) traffic_analyzer_gmii0
                      (
                          .clk(clk),
                          .resetn(~rst),

                          .gmii_d(gmii_d),
                          .gmii_en(gmii_en),
                          .gmii_er(gmii_er),

                          .sec(sec),
                          .nsec(nsec),

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

//  always @(posedge S_AXI_ACLK) begin
//           $display("axi time=%t, S_AXI_RDATA=%x", $time, S_AXI_RDATA);
//  end

always @(negedge S_AXI_ACLK) begin
    //    $display("axi time=%t, S_AXI_RDATA=%x", $time, S_AXI_RDATA);
end

initial begin
    clk = 1;
    rst = 0;

    S_AXI_ARESETN=1;
    S_AXI_ACLK = 1;

    #(10*CLK_PERIOD_NS) rst = 1;

    #(10*CLK_PERIOD_NS) rst = 0;

    #(10*CLK_PERIOD_NS) S_AXI_ARESETN=0;

    #(10*CLK_PERIOD_NS) S_AXI_ARESETN=1;

    $display("Reading frame ...");
    len = 64+8; // frame includes layer1 preamble 55555555555555d5
    $readmemh("frame.mem", frame, 0, len-1);

    axi_write(TG_BASEADDR+`REG_FRAME_SIZE_ADDR, len);

    for (i = 0; i < len/4; i = i + 1) begin
        axi_write(TG_BASEADDR+`REG_FRAME_BUF_ADDR, {frame[4*i],frame[4*i+1], frame[4*i+2], frame[4*i+3]});
        $display("[%d]%x", i, {frame[4*i],frame[4*i+1], frame[4*i+2], frame[4*i+3]});
    end
    axi_write(TG_BASEADDR+`REG_FRAME_SIZE_ADDR, len); /*workaround*/

    #(8*84*50*CLK_PERIOD_NS)

    axi_read(TA_BASEADDR+`REG_PKTS_ADDR, data64[63:32]);
    axi_read(TA_BASEADDR+`REG_PKTS_ADDR+4, data64[31:0]);
    $display("pkts=%d", data64);
    if(data64 != 0) begin
        $error("Initial pkts counter not 0 (%d)", data64);
        $fatal;
    end

    // with less then 10 frames configured the testcase should fail
    data64 = 10;
    axi_write(TG_BASEADDR+`REG_TOTAL_FRAMES_ADDR,  data64[63:32]);
    axi_write(TG_BASEADDR+`REG_TOTAL_FRAMES_ADDR+4,  data64[31:0]);

    axi_write(TG_BASEADDR+`REG_CONTROL_ADDR, 32'h00000001);

    #(84*10*CLK_PERIOD_NS-1*CLK_PERIOD_NS)

     axi_read(TA_BASEADDR+`REG_PKTS_ADDR, data64[63:32]);
    axi_read(TA_BASEADDR+`REG_PKTS_ADDR+4, data64[31:0]);
    $display("pkts=%d", data64);

    if(data64 != 10) begin
        $error("Received pkts counter not 10 (%d)", data64);
        $fatal;
    end

    axi_read(TA_BASEADDR+`REG_OCTETS_ADDR, data64[63:32]);
    axi_read(TA_BASEADDR+`REG_OCTETS_ADDR+4, data64[31:0]);
    $display("octets=%d", data64);

    if(data64 != 720) begin
        $error("Received octets counter not 720 (%d)", data64);
        $fatal;
    end

    axi_read(TA_BASEADDR+`REG_OCTETS_IDLE_ADDR, data64[63:32]);
    axi_read(TA_BASEADDR+`REG_OCTETS_IDLE_ADDR+4, data64[31:0]);
    $display("octets-idle=%d", data64);

    if(data64 < 8*84*50+10*12) begin
        $error("Received octets-idle counter less then %d (%d)", 8*84*50+10*12, data64);
        $fatal;
    end

    axi_read(TA_BASEADDR+`REG_TIMESTAMP_SEC_ADDR, data64[63:32]);
    axi_read(TA_BASEADDR+`REG_TIMESTAMP_SEC_ADDR+4, data64[31:0]);
    $display("timestamp.sec=%d", data64);

    axi_read(TA_BASEADDR+`REG_TIMESTAMP_NSEC_ADDR, data);
    $display("timestamp.nsec=%d", data);

    axi_read(TA_BASEADDR+`REG_FRAME_SIZE_ADDR, data);
    $display("frame_size=%d", data);


    axi_write(TG_BASEADDR+`REG_CONTROL_ADDR, 32'h00000002);

    #(8*84*CLK_PERIOD_NS)

    len = data;
    for (i = 0; i < (len+3)/4; i = i + 1) begin
        axi_read(TA_BASEADDR+`REG_FRAME_BUF_ADDR, data);
        $display("[%d]%x", i, data);
    end

    //wait (sec[3]);

    $finish;

end

endmodule
