`timescale 1ns/1ps
`include "rtclock_cpu_regs.v"
`include "rtclock_cpu_regs_defines.v"

module rtclock
       #(
           parameter C_S_AXI_DATA_WIDTH    = 32,
           parameter C_S_AXI_ADDR_WIDTH    = 12,
           parameter C_BASEADDR            = 32'h00000000,
           parameter C_CLK_TO_NS_RATIO    = 8

       )
(
    input clk,
    input resetn,
    input pps,

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
    output                                    S_AXI_AWREADY

);



parameter nsec_modulo = 31'd1000000000;


reg      [`REG_ID_BITS]    id_reg;
reg      [`REG_VERSION_BITS]    version_reg;
reg      [`REG_FLIP_BITS]    ip2cpu_flip_reg;
wire     [`REG_FLIP_BITS]    cpu2ip_flip_reg;
wire     [`REG_CONTROL_BITS] control_reg;
wire     [`REG_SEC_CONFIG_BITS] sec_config_reg;

reg [47:0] sec_next;
reg [29:0] nsec_next;
reg sec_inc;

integer pps_enabled;
reg [47:0] sec_next_pps;
reg [29:0] nsec_next_pps;
reg sec_inc_pps;
reg pps_enabled_prev;
reg pps_prev;


//Registers section
 rtclock_cpu_regs
 #(
   .C_S_AXI_DATA_WIDTH (C_S_AXI_DATA_WIDTH),
   .C_S_AXI_ADDR_WIDTH (C_S_AXI_ADDR_WIDTH),
   .C_BASE_ADDRESS        (C_BASEADDR)
 ) opl_cpu_regs_inst
 (
   // General ports
    .clk                    (clk),
    .resetn                 (resetn),
   // AXI Lite ports
    .S_AXI_ACLK             (S_AXI_ACLK),
    .S_AXI_ARESETN          (S_AXI_ARESETN),
    .S_AXI_AWADDR           (S_AXI_AWADDR),
    .S_AXI_AWVALID          (S_AXI_AWVALID),
    .S_AXI_WDATA            (S_AXI_WDATA),
    .S_AXI_WSTRB            (S_AXI_WSTRB),
    .S_AXI_WVALID           (S_AXI_WVALID),
    .S_AXI_BREADY           (S_AXI_BREADY),
    .S_AXI_ARADDR           (S_AXI_ARADDR),
    .S_AXI_ARVALID          (S_AXI_ARVALID),
    .S_AXI_RREADY           (S_AXI_RREADY),
    .S_AXI_ARREADY          (S_AXI_ARREADY),
    .S_AXI_RDATA            (S_AXI_RDATA),
    .S_AXI_RRESP            (S_AXI_RRESP),
    .S_AXI_RVALID           (S_AXI_RVALID),
    .S_AXI_WREADY           (S_AXI_WREADY),
    .S_AXI_BRESP            (S_AXI_BRESP),
    .S_AXI_BVALID           (S_AXI_BVALID),
    .S_AXI_AWREADY          (S_AXI_AWREADY),


   // Register ports
   .id_reg          (id_reg),
   .version_reg          (version_reg),
   .ip2cpu_flip_reg          (ip2cpu_flip_reg),
   .cpu2ip_flip_reg          (cpu2ip_flip_reg),
   .control_reg          (control_reg),
   .sec_config_reg          (sec_config_reg),
   .sec_state_reg          (sec)

);
 
    always @(posedge clk) begin
        pps_enabled = control_reg[0];

        if (~resetn) begin
            sec <= 0;
            nsec <= 0;
            sec_next <= 0;
            nsec_next <= C_CLK_TO_NS_RATIO;
            sec_inc <= 0;
        end
        else begin
            if(pps_enabled) begin
                sec <= sec_next_pps;
                nsec <= nsec_next_pps;
            end
            else begin
                sec <= sec_next;
                nsec <= nsec_next;
            end

            // 1/2 - no external pps sync
            sec_inc = (nsec_next >= (nsec_modulo-C_CLK_TO_NS_RATIO))? 1'b1: 1'b0;
            if(sec_inc) begin
                sec_next <= sec_next + 1;
                nsec_next <= nsec_next - (nsec_modulo-C_CLK_TO_NS_RATIO);
            end
            else begin
                nsec_next <= nsec_next + C_CLK_TO_NS_RATIO;
            end

            // 2/2 - with pps sync
            sec_inc_pps = (nsec_next_pps >= (nsec_modulo-C_CLK_TO_NS_RATIO))? 1'b1: 1'b0;
            pps_prev <= pps;
            pps_enabled_prev <= pps_enabled;
            if(pps_enabled_prev == 0 && pps_enabled == 1) begin
                sec_next_pps <= sec_config_reg;
                nsec_next_pps <= 0;
            end
            else if(pps_prev == 0 && pps == 1) begin
                sec_next_pps <= sec_next_pps + 1;
                nsec_next_pps <= C_CLK_TO_NS_RATIO;
                sec_inc_pps <= 0;
            end
            else if(~sec_inc_pps) begin
                nsec_next_pps <= nsec_next_pps + C_CLK_TO_NS_RATIO;
            end
        end
    end

endmodule
