`timescale 1ns/1ps
`include "traffic_generator_cpu_regs.v"
`include "traffic_generator_cpu_regs_defines.v"

module traffic_generator
#(
    parameter C_S_AXI_DATA_WIDTH    = 32,
    parameter C_S_AXI_ADDR_WIDTH    = 12,
    parameter C_M_AXIS_DATA_WIDTH   = 8,
    parameter C_BASEADDR            = 32'h00000000
)
(
    // Global Ports
    input axis_aclk,
    input axis_resetn,

    // Master Stream Ports (interface to data path)
    output reg [C_M_AXIS_DATA_WIDTH - 1:0] m_axis_tdata,
    output reg [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] m_axis_tkeep,
    output reg m_axis_tvalid,
    input  m_axis_tready,
    output reg m_axis_tlast,

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

   reg      [2-1:0]     state;
   reg                  run;
   reg      [16-1:0]    interframe_gap;
   reg      [16-1:0]    frame_size;
   reg      [16-1:0]    gap_counter;
   reg      [16-1:0]    data_counter;


//Registers section
 traffic_generator_cpu_regs 
 #(
   .C_S_AXI_DATA_WIDTH (C_S_AXI_DATA_WIDTH),
   .C_S_AXI_ADDR_WIDTH (C_S_AXI_ADDR_WIDTH),
   .C_BASE_ADDRESS        (C_BASEADDR)
 ) opl_cpu_regs_inst
 (   
   // General ports
    .clk                    (axis_aclk),
    .resetn                 (axis_resetn),
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
   .cpu2ip_flip_reg          (cpu2ip_flip_reg)
);


always @(posedge axis_aclk) begin
    if(~axis_resetn) begin
          m_axis_tdata <= 0;
          m_axis_tkeep <= 0;
          m_axis_tvalid <= 0;
          m_axis_tlast <= 0;
 
          state <= 2'b00;
          frame_size <= 60;
          interframe_gap <= 4+12+8;
          run <= 1;
    end
    else begin
          case(state)
          2'b00 : begin
           m_axis_tdata <= 0;
           m_axis_tkeep <= 0;
           m_axis_tvalid <= 0;
           m_axis_tlast <= 0;

           if(run != 0) begin
               data_counter<=1;
               gap_counter<=2; /* minimum 2 cycles gap */

               state <= 2'b01;
           end
           else begin
               state <= 2'b00;
           end
          end
          2'b01 : begin
           data_counter<=data_counter+1;

           m_axis_tdata <= data_counter;
           m_axis_tkeep <= 1;
           m_axis_tvalid <= 1;

           if(data_counter>=frame_size) begin
               m_axis_tlast <= 1;

               state <= 2'b10;
           end
           else begin
               m_axis_tlast <= 0;

               state <= 2'b01;
           end
          end
          2'b10 : begin
           gap_counter<=gap_counter+1;

           m_axis_tdata <= 0;
           m_axis_tkeep <= 0;
           m_axis_tvalid <= 0;
           m_axis_tlast <= 0;
           if(gap_counter>=interframe_gap) begin
               state <= 2'b00;
           end
           else begin
               state <= 2'b10;
           end
          end
          endcase
    end
end
//   assign m_axis_tdata = 8'b00000000;
//   assign m_axis_tkeep = 0;
//   assign m_axis_tvalid = 0;
//   assign m_axis_tlast = 0;
 
endmodule // traffic_generator
