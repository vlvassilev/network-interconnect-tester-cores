`timescale 1ns/1ps
`include "traffic_generator_gmii_cpu_regs.v"
`include "traffic_generator_gmii_cpu_regs_defines.v"

`define C_GMII_DATA_WIDTH 8

module traffic_generator_gmii
#(
    parameter C_S_AXI_DATA_WIDTH    = 32,
    parameter C_S_AXI_ADDR_WIDTH    = 12,
    parameter C_BASEADDR            = 32'h00000000
)
(
    // Global Ports
    input clk,
    input resetn,

    // GMII OUT ports
    output reg [8 - 1:0] gmii_out_txd,
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

   reg      [`REG_ID_BITS]    id_reg;
   reg      [`REG_VERSION_BITS]    version_reg;
   reg      [`REG_FLIP_BITS]    ip2cpu_flip_reg;
   wire     [`REG_FLIP_BITS]    cpu2ip_flip_reg;
   wire     [`REG_CONTROL_BITS] control_reg;

   reg      [2-1:0]     state;
   reg                  run;
   reg      [16-1:0]    interframe_gap;
   reg      [16-1:0]    frame_size;
   reg      [16-1:0]    gap_counter;
   reg      [16-1:0]    gap_counter_last;
   reg      [16-1:0]    data_counter;
   reg      [16-1:0]    data_counter_last;
   reg      [7:0]       ethernet_frame[71:0];

   integer i;

//Registers section
 traffic_generator_gmii_cpu_regs
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
   .control_reg          (control_reg)
);


always @(posedge clk) begin

    run <= control_reg[0];

    if(~resetn) begin
          gmii_out_txd <= 0;
          gmii_out_tx_en <= 0;
          gmii_out_tx_er <= 0;

          state <= 2'b00;
          frame_size <= 72; /* 7+1 preamble + 60 payload including MAC src and destination + 4 CRC */
          interframe_gap <= 12;
	  gap_counter <= 0;
    end
    else begin
          case(state)
          2'b00 : begin
           gmii_out_txd <= 0;
           gmii_out_tx_en <= 0;
           gmii_out_tx_er <= 0;

           if(run != 0) begin
               data_counter<=0;
               data_counter_last<=frame_size-1;

               gap_counter<=0;
               gap_counter_last<=interframe_gap-2;

               for (i=0;i<=7;i=i+1)
                   ethernet_frame[i] = 8'h55;

               ethernet_frame[7] = 8'hD5;
               for (i=0;i<=60;i=i+1)
                   ethernet_frame[i+8] = i+1;
               ethernet_frame[8+60+0]=8'h34;
               ethernet_frame[8+60+1]=8'h4c;
               ethernet_frame[8+60+2]=8'ha0;
               ethernet_frame[8+60+3]=8'h62;

               state <= 2'b01;
           end
           else begin
               state <= 2'b00;
           end
          end
          2'b01 : begin
           data_counter<=data_counter+1;

           gmii_out_txd <= ethernet_frame[data_counter];
           gmii_out_tx_en <= 1;
           gmii_out_tx_er <= 0;

           if(data_counter<data_counter_last) begin
               state <= 2'b01;
           end
           else begin
               state <= 2'b10;
           end
          end
          2'b10 : begin
           gap_counter<=gap_counter+1;

           gmii_out_txd <= 0;
           gmii_out_tx_en <= 0;
           gmii_out_tx_er <= 0;
           if(gap_counter<gap_counter_last) begin
               state <= 2'b10;
           end
           else begin
               state <= 2'b00;
           end
          end

          endcase
    end
end
 
endmodule // traffic_generator_gmii
