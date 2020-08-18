`timescale 1ns/1ps
`include "gmii_mux_cpu_regs.v"
`include "gmii_mux_cpu_regs_defines.v"

module gmii_mux
#(
    parameter C_NUM_INPUTS=3,

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

    // GMII input 2
    input [7:0] gmii_in_2_txd,
    input gmii_in_2_tx_en,
    input gmii_in_2_tx_er,

    // GMII input 3
    input [7:0] gmii_in_3_txd,
    input gmii_in_3_tx_en,
    input gmii_in_3_tx_er,

    // GMII input 4
    input [7:0] gmii_in_4_txd,
    input gmii_in_4_tx_en,
    input gmii_in_4_tx_er,

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


   reg [`REG_SELECT_BITS] select_reg_r;
   // GMII input 0
   reg [7:0] gmii_in_0_txd_r;
   reg gmii_in_0_tx_en_r;
   reg gmii_in_0_tx_er_r;

   // GMII input 1
   reg [7:0] gmii_in_1_txd_r;
   reg gmii_in_1_tx_en_r;
   reg gmii_in_1_tx_er_r;

   // GMII input 2
   reg [7:0] gmii_in_2_txd_r;
   reg gmii_in_2_tx_en_r;
   reg gmii_in_2_tx_er_r;

   // GMII input 3
   reg [7:0] gmii_in_3_txd_r;
   reg gmii_in_3_tx_en_r;
   reg gmii_in_3_tx_er_r;

   // GMII input 4
   reg [7:0] gmii_in_4_txd_r;
   reg gmii_in_4_tx_en_r;
   reg gmii_in_4_tx_er_r;

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

always @(posedge gtx_clk) begin
        select_reg_r <= select_reg;
        gmii_in_0_txd_r <= gmii_in_0_txd;
        gmii_in_0_tx_en_r <= gmii_in_0_tx_en;
        gmii_in_0_tx_er_r <= gmii_in_0_tx_er;
        gmii_in_1_txd_r <= gmii_in_1_txd;
        gmii_in_1_tx_en_r <= gmii_in_1_tx_en;
        gmii_in_1_tx_er_r <= gmii_in_1_tx_er;
        gmii_in_2_txd_r <= gmii_in_2_txd;
        gmii_in_2_tx_en_r <= gmii_in_2_tx_en;
        gmii_in_2_tx_er_r <= gmii_in_2_tx_er;
        gmii_in_3_txd_r <= gmii_in_3_txd;
        gmii_in_3_tx_en_r <= gmii_in_3_tx_en;
        gmii_in_3_tx_er_r <= gmii_in_3_tx_er;
        gmii_in_4_txd_r <= gmii_in_4_txd;
        gmii_in_4_tx_en_r <= gmii_in_4_tx_en;
        gmii_in_4_tx_er_r <= gmii_in_4_tx_er;

        case(select_reg_r)
        8'h01 : begin
          gmii_out_txd <= gmii_in_1_txd_r;
          gmii_out_tx_en <= gmii_in_1_tx_en_r;
          gmii_out_tx_er <= gmii_in_1_tx_er_r;
        end
        8'h02 : begin
          gmii_out_txd <= gmii_in_2_txd_r;
          gmii_out_tx_en <= gmii_in_2_tx_en_r;
          gmii_out_tx_er <= gmii_in_2_tx_er_r;
        end
        8'h03 : begin
          gmii_out_txd <= gmii_in_3_txd_r;
          gmii_out_tx_en <= gmii_in_3_tx_en_r;
          gmii_out_tx_er <= gmii_in_3_tx_er_r;
        end
        8'h04 : begin
          gmii_out_txd <= gmii_in_4_txd_r;
          gmii_out_tx_en <= gmii_in_4_tx_en_r;
          gmii_out_tx_er <= gmii_in_4_tx_er_r;
        end
        default : begin
                gmii_out_txd <= gmii_in_0_txd_r;
                gmii_out_tx_en <= gmii_in_0_tx_en_r;
                gmii_out_tx_er <= gmii_in_0_tx_er_r;
        end
        endcase
end
endmodule // gmii_mux

