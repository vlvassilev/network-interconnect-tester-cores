`timescale 1ns/1ps
`include "gmii_mux_cpu_regs.v"
`include "gmii_mux_cpu_regs_defines.v"

module gmii_mux
#(
    parameter C_NUM_INPUTS=2,

 // AXI Registers Data Width
    parameter C_S_AXI_DATA_WIDTH    = 32,          
    parameter C_S_AXI_ADDR_WIDTH    = 12,          
    parameter C_BASEADDR            = 32'h00000000


)
(
    // Global Ports
    input gtx_clk,

    // GMII input 0
    input [7:0] gmii_in_0_txd,
    input gmii_in_0_tx_en,
    input gmii_in_0_tx_er,

    // GMII input 1
    input [7:0] gmii_in_1_txd,
    input gmii_in_1_tx_en,
    input gmii_in_1_tx_er,

    // GMII output
    output reg [7:0] gmii_out_txd,
    output reg gmii_out_tx_en,
    output reg gmii_out_tx_er,

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

   reg      [`REG_ID_BITS]    id_reg = `REG_ID_DEFAULT;
   reg      [`REG_VERSION_BITS]    version_reg = `REG_VERSION_DEFAULT;
   wire     [`REG_SELECT_BITS]    select_reg;
 
   // Handle output
   //assign a = b;

//Registers section
 gmii_mux_cpu_regs 
 #(
   .C_BASE_ADDRESS        (C_BASEADDR),
   .C_S_AXI_DATA_WIDTH (C_S_AXI_DATA_WIDTH),
   .C_S_AXI_ADDR_WIDTH (C_S_AXI_ADDR_WIDTH)
 ) opl_cpu_regs_inst
 (   
   // General ports
    .clk                    (gtx_clk),
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
    .select_reg          (select_reg)
);

   //assign q = q_reg[0];

always @(posedge gtx_clk)
        if(select_reg[0]) begin
                gmii_out_txd <= #1 gmii_in_0_txd;
                gmii_out_tx_en <= #1 gmii_in_0_tx_en;
                gmii_out_tx_er <= #1 gmii_in_0_tx_er;
        end
        else begin
                gmii_out_txd <= #1 gmii_in_1_txd;
                gmii_out_tx_en <= #1 gmii_in_1_tx_en;
                gmii_out_tx_er <= #1 gmii_in_1_tx_er;
        end	
 
endmodule // gmii_mux
