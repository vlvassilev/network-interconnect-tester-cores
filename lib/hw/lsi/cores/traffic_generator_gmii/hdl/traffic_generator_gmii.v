`timescale 1ns/1ps
`include "traffic_generator_gmii_cpu_regs.v"
`include "traffic_generator_gmii_cpu_regs_defines.v"

`define C_GMII_DATA_WIDTH 8
`define C_FRAME_BUF_ADDRESS_WIDTH 8

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
    output reg [8 - 1:0] gmii_d,
    output reg gmii_en,
    output reg gmii_er,

    input [47:0] sec,
    input [29:0] nsec,

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
   wire     [`REG_INTERFRAME_GAP_BITS] interframe_gap_reg;
   wire     [`REG_INTERBURST_GAP_BITS] interburst_gap_reg;
   wire     [`REG_FRAMES_PER_BURST_BITS] frames_per_burst_reg;
   wire     [`REG_TOTAL_FRAMES_BITS] total_frames_reg;
   wire     [`REG_FRAME_SIZE_BITS] frame_size_reg;
   wire     [31:0] frame_buf_in_data;
   wire     [7:0] frame_buf_in_address;
   wire     frame_buf_in_wr;

   reg      [2-1:0]     state;
   reg                  run;
   reg      [31:0]      interframe_gap;
   reg      [10:0]      frame_size;
   reg      [31:0]    gap_counter;
   reg      [31:0]    gap_counter_last;
   reg      [31:0]    data_counter;
   reg      [31:0]    data_counter_last;
   reg      [7:0]     ethernet_frame[71:0];

   integer     data;

   reg    [`C_FRAME_BUF_ADDRESS_WIDTH-1:0]  frame_buf_out_address;
   reg    [`C_FRAME_BUF_ADDRESS_WIDTH-1:0]  next_frame_buf_out_address;
   wire   [31:0] frame_buf_out_data;


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
   .control_reg          (control_reg),
   .interframe_gap_reg(interframe_gap_reg),
   .interburst_gap_reg(interburst_gap_reg),
   .frames_per_burst_reg(frames_per_burst_reg),
   .total_frames_reg(total_frames_reg),
   .frame_size_reg(frame_size_reg),
   .frame_buf_address(frame_buf_in_address),
   .frame_buf_data(frame_buf_in_data),
   .frame_buf_wr(frame_buf_in_wr)

);

bram_io #(
            .DATA_WIDTH(32),
            .ADDR_WIDTH(8) // 2048 bytes
        ) bram_io_inst (
            .rst(~resetn),

            .i_clk(S_AXI_ACLK),
            .i_wr(frame_buf_in_wr),
            .i_addr(frame_buf_in_address),
            .i_data(frame_buf_in_data),

            .o_clk(clk),
            .o_addr(frame_buf_out_address),
            .o_data(frame_buf_out_data)
        );

always @(posedge clk) begin

    run <= control_reg[0];

    if(~resetn) begin
          gmii_d <= 0;
          gmii_en <= 0;
          gmii_er <= 0;

          state <= 2'b00;
	  gap_counter <= 0;
    end
    else begin
          case(state)
          2'b00 : begin
           gmii_d <= 0;
           gmii_en <= 0;
           gmii_er <= 0;

           if(run != 0) begin
               data_counter<=0;
               data_counter_last<=frame_size_reg-1;

               gap_counter<=0;
               gap_counter_last<=interframe_gap_reg-2;

               state <= 2'b01;
           end
           else begin
               state <= 2'b00;
           end
          end
          2'b01 : begin
           data_counter<=data_counter+1;

           case(data_counter[1:0])
               2'b00 : begin
                   data = frame_buf_out_data[31:24];
               end
               2'b01 : begin
                   data = frame_buf_out_data[23:16];
               end
               2'b10 : begin
                   data = frame_buf_out_data[15:8];
               end
               2'b11 : begin
                   data = frame_buf_out_data[7:0];
               end
           endcase
           if(data_counter[1:0] == 2'b10) begin
               frame_buf_out_address <= frame_buf_out_address+1;
           end
           gmii_d <= data; //ethernet_frame[data_counter];
           gmii_en <= 1;
           gmii_er <= 0;

           if(data_counter<data_counter_last) begin
               state <= 2'b01;
           end
           else begin
               state <= 2'b10;
           end
          end
          2'b10 : begin
           gap_counter<=gap_counter+1;

           gmii_d <= 0;
           gmii_en <= 0;
           gmii_er <= 0;
           if(gap_counter<gap_counter_last) begin
               state <= 2'b10;
           end
           else begin
               state <= 2'b00;
               frame_buf_out_address <= 0;
           end
          end

          endcase
    end
end
 
endmodule // traffic_generator_gmii
