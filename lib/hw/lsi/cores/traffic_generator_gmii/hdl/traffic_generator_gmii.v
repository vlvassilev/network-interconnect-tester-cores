`timescale 1ns/1ps
`include "traffic_generator_gmii_cpu_regs.v"
`include "traffic_generator_gmii_cpu_regs_defines.v"
//`include "ethernet_crc_8.v"

`define C_GMII_DATA_WIDTH 8
`define C_FRAME_BUF_ADDRESS_WIDTH 8

module traffic_generator_gmii
#(
    parameter C_S_AXI_DATA_WIDTH    = 32,
    parameter C_S_AXI_ADDR_WIDTH    = 12,
    parameter C_BASEADDR            = 32'h00000000,
    parameter C_FRAME_BUF_ADDRESS_WIDTH   = 9
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
   reg      [`REG_PKTS_BITS]    pkts_reg;
   wire     [31:0] frame_buf_in_data;
   wire     [C_FRAME_BUF_ADDRESS_WIDTH-1:0] frame_buf_in_address;
   wire     frame_buf_in_wr;

   reg      [3-1:0]     state;
   reg      [3-1:0]     next_state;
   reg                  run;
   reg      [31:0]      interframe_gap;
   reg      [10:0]      frame_size;
   reg      [31:0]    gap_counter;
   reg      [31:0]    gap_counter_last;
   reg      [31:0]    data_counter;
   reg      [31:0]    data_counter_last;
   reg      [7:0]     ethernet_frame[71:0];
   reg      [`REG_TOTAL_FRAMES_BITS]    frames;
   reg      [4:0]    seqnum_counter;
   reg      [4:0]    timestamp_counter;
   reg                timestamp_enable;
   reg      [7:0]     timestamp[9:0];
   reg      [4:0]    crc_counter;
   reg      [7:0]     data_t0;
   reg      [63:0]    sequence_number;

   integer     data;

   reg    [C_FRAME_BUF_ADDRESS_WIDTH-1:0]  frame_buf_out_address;
   wire   [31:0] frame_buf_out_data;
   reg    [31:0] frame_buf_out_data_r;

   //crc inputs
   reg         crc_calc;
   reg         crc_init;
   reg         crc_d_valid;
   //crc outputs
   wire [31:0] crc_reg;
   wire [7:0]  crc;


   integer i;

//Registers section
 traffic_generator_gmii_cpu_regs
 #(
   .C_S_AXI_DATA_WIDTH (C_S_AXI_DATA_WIDTH),
   .C_S_AXI_ADDR_WIDTH (C_S_AXI_ADDR_WIDTH),
   .C_BASE_ADDRESS        (C_BASEADDR),
   .C_FRAME_BUF_ADDRESS_WIDTH (C_FRAME_BUF_ADDRESS_WIDTH)
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
   .pkts_reg(pkts_reg),
   .frame_buf_address(frame_buf_in_address),
   .frame_buf_data(frame_buf_in_data),
   .frame_buf_wr(frame_buf_in_wr)

);

bram_io #(
            .DATA_WIDTH(32),
            .ADDR_WIDTH(C_FRAME_BUF_ADDRESS_WIDTH) // 2048 bytes
        ) bram_io_inst (
            .rst(~resetn),

            .i_clk(clk),
            .i_wr(frame_buf_in_wr),
            .i_addr(frame_buf_in_address),
            .i_data(frame_buf_in_data),

            .o_clk(clk),
            .o_addr(frame_buf_out_address),
            .o_data(frame_buf_out_data)
        );

ethernet_crc_8 ethernet_crc_8_0 (.clk(clk), .reset(~resetn), .d(data_t0), .calc(crc_calc), .init(crc_init), .d_valid(crc_d_valid), .crc_reg(crc_reg), .crc(crc));

always @(posedge clk) begin

    run <= control_reg[0];
    timestamp_enable <= control_reg[1];

    if(~resetn) begin
          gmii_d <= 0;
          gmii_en <= 0;
          gmii_er <= 0;

          state <= 2'b00;
	  gap_counter <= 0;

          pkts_reg <= 0;
          frame_buf_out_address <= 0;

          crc_calc <= 0;
          crc_init <= 1;
          crc_d_valid <= 0;

    end
    else begin
           //$display("gmii_d data=%x, crc=%x, crc_reg=%x",gmii_d,crc,crc_reg);

          case(state)
          0 : begin
           gmii_d <= 0;
           gmii_en <= 0;
           gmii_er <= 0;

           if(run != 0) begin
               data_counter<=0;
               data_counter_last<=frame_size_reg-1;

               gap_counter<=0;
               gap_counter_last<=interframe_gap_reg-3;

               seqnum_counter <= 0;
               timestamp_counter <= 0;
               crc_counter <= 0;

               if(frames != total_frames_reg || total_frames_reg == 0) begin
                   state <= 1;
                   frame_buf_out_data_r <= frame_buf_out_data;
                   frame_buf_out_address <= 1;
               end
           end
           else begin
               state <= 0;
               frames <= 0;
           end
          end
          1 : begin
           data_counter<=data_counter+1;

           case(data_counter[1:0])
               2'b00 : begin
                   data = frame_buf_out_data_r[31:24];
               end
               2'b01 : begin
                   data = frame_buf_out_data_r[23:16];
               end
               2'b10 : begin
                   data = frame_buf_out_data_r[15:8];
               end
               2'b11 : begin
                   data = frame_buf_out_data_r[7:0];
               end
           endcase
           if(data_counter[1:0] == 2'b11) begin
               frame_buf_out_address <= frame_buf_out_address+1;
               frame_buf_out_data_r <= frame_buf_out_data;
           end

           data_t0 <= data; /* delay data 1 cycle for CRC pipeline */

           if(data_counter>0) begin
               gmii_en <= 1;
               gmii_d <= data_t0;
               gmii_er <= 0;
           end

           if(data_counter == 1) begin
               timestamp[0]<=sec[47:40];
               timestamp[1]<=sec[39:32];
               timestamp[2]<=sec[31:24];
               timestamp[3]<=sec[23:16];
               timestamp[4]<=sec[15:8];
               timestamp[5]<=sec[7:0];
               timestamp[6]<=nsec[29:24]; //!
               timestamp[7]<=nsec[23:16];
               timestamp[8]<=nsec[15:8];
               timestamp[9]<=nsec[7:0];
           end

           if(data_counter<data_counter_last) begin
               state <= 2'b01;
           end
           else begin
               state <= next_state; //2'b10;
               pkts_reg <= pkts_reg + 1;
           end

           //next_state
           if(timestamp_enable) begin
               next_state <= 3;
           end
           else begin
               next_state <= 6;
           end
           if(data_counter == 8) begin
              crc_calc <= 1;
              crc_init <= 0;
              crc_d_valid <= 1;
           end

          end

          2 : begin
           gap_counter<=gap_counter+1;

           gmii_d <= 0;
           gmii_en <= 0;
           gmii_er <= 0;

           frame_buf_out_address <= 0;
           if(gap_counter<gap_counter_last) begin
               state <= 2;
           end
           else begin
               state <= 0;
               frames <= frames + 1;
           end

           crc_calc <= 0;
           crc_init <= 1;
           crc_d_valid <= 0;

          end

          3 : begin
           seqnum_counter<=seqnum_counter+1;

           data = frames[8*(7-seqnum_counter) +: 8];

           data_t0 <= data;

           gmii_d <= data_t0;

           if(seqnum_counter==7) begin
               state <= 4;
           end
          end

          4 : begin
           timestamp_counter<=timestamp_counter+1;

           data_t0 <= timestamp[timestamp_counter];

           gmii_d <= data_t0;

           if(timestamp_counter==9) begin
               state <= 5;
           end
          end

          5 : begin
           crc_counter<=crc_counter+1;

           crc_calc <= 0;

           if(crc_counter==0) begin
               gmii_d <= data_t0;
           end
           else begin
               gmii_d <= crc;
           end

           gmii_en <= 1;
           gmii_er <= 0;

           if(crc_counter==4) begin
               state <= 2;
           end
          end

          6 : begin
              gmii_d <= data_t0;
              state <= 2;
          end

          endcase
    end
end

always @(posedge clk) begin
    if (~resetn) begin
        id_reg <= #1    `REG_ID_DEFAULT;
        version_reg <= #1    `REG_VERSION_DEFAULT;
        ip2cpu_flip_reg <= #1    `REG_FLIP_DEFAULT;
    end
    else begin
        id_reg <= #1    `REG_ID_DEFAULT;
        version_reg <= #1    `REG_VERSION_DEFAULT;
        ip2cpu_flip_reg <= #1    ~cpu2ip_flip_reg;
    end
end
 
endmodule // traffic_generator_gmii
