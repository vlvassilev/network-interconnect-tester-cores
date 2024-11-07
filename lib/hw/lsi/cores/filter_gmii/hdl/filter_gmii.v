`timescale 1ns/1ps
`include "filter_gmii_cpu_regs.v"
`include "filter_gmii_cpu_regs_defines.v"

module filter_gmii
#(

 // AXI Registers Data Width
    parameter C_S_AXI_DATA_WIDTH    = 32,          
    parameter C_S_AXI_ADDR_WIDTH    = 12,          
    parameter C_BASEADDR            = 32'h00000000

)
(
    // Global Ports
    input clk,

    // GMII input
    input [7:0] gmii_d_in,
    input gmii_en_in,
    input gmii_er_in,

    // GMII output
    output reg [7:0] gmii_d_out,
    output reg gmii_en_out,
    output reg gmii_er_out,

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
   wire     [`REG_MIN_INTERFRAME_GAP_BITS]    min_interframe_gap_reg;


   reg [`REG_MIN_INTERFRAME_GAP_BITS] min_interframe_gap_reg_r;
   // GMII input 0
   reg [7:0] gmii_d_in_r;
   reg gmii_en_in_r;
   reg gmii_er_in_r;

   reg     [7:0]   state = 0;
   reg     [31:0]  interframe_gap_delay = 0;

//Registers section
 filter_gmii_cpu_regs 
 #(
   .C_BASE_ADDRESS        (C_BASEADDR),
   .C_S_AXI_DATA_WIDTH (C_S_AXI_DATA_WIDTH),
   .C_S_AXI_ADDR_WIDTH (C_S_AXI_ADDR_WIDTH)
 ) opl_cpu_regs_inst
 (   
   // General ports
    .clk                    (clk),
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
    .min_interframe_gap_reg          (min_interframe_gap_reg)
);

always @(posedge clk) begin
    min_interframe_gap_reg_r <= min_interframe_gap_reg;
    gmii_d_in_r <= gmii_d_in;
    gmii_en_in_r <= gmii_en_in;
    gmii_er_in_r <= gmii_er_in;
end

always @(posedge clk) begin
    case(state)
    8'h01 : begin
        gmii_d_out <= gmii_d_in_r;
        gmii_en_out <= gmii_en_in_r;
        gmii_er_out <= gmii_er_in_r;
        if(gmii_en_in==0 && gmii_en_in_r==1) begin
            state <= 0;
            interframe_gap_delay <= min_interframe_gap_reg_r-9; //subtracted 8 octets the size of the preamble + 1 fifo delay
        end
    end
    default: begin
        gmii_d_out <= 0;
        gmii_en_out <= 0;
        gmii_er_out <= 0;
        if(interframe_gap_delay>0) begin
            interframe_gap_delay <= interframe_gap_delay - 1;
        end
        if(gmii_en_in==1 && gmii_en_in_r==0 && interframe_gap_delay==0) begin
            state <= 1;
        end
    end
    endcase
end
endmodule // filter_gmii
