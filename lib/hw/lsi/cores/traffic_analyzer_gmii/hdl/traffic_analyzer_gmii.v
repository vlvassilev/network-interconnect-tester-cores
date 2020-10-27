`timescale 1ns/1ps
`include "traffic_analyzer_gmii_cpu_regs.v"
`include "traffic_analyzer_gmii_cpu_regs_defines.v"

`define C_GMII_DATA_WIDTH 8
`define C_FRAME_BUF_ADDRESS_WIDTH 8

module traffic_analyzer_gmii
       #(
           parameter C_S_AXI_DATA_WIDTH    = 32,
           parameter C_S_AXI_ADDR_WIDTH    = 12,
           parameter C_BASEADDR            = 32'h00000000
       )
       (
           // Global Ports
           input clk,
           input resetn,

           // GMII IN ports
           input [8 - 1:0] gmii_d,
           input gmii_en,
           input gmii_er,

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
reg     [`REG_PKTS_BITS] pkts_reg;
reg     [`REG_OCTETS_BITS] octets_reg;
reg     [`REG_OCTETS_IDLE_BITS] octets_idle_reg;
reg     [`REG_TIMESTAMP_SEC_BITS] timestamp_sec_reg;
reg     [`REG_TIMESTAMP_NSEC_BITS] timestamp_nsec_reg;
reg     [`REG_FRAME_SIZE_BITS] frame_size_reg;
reg     [`REG_FRAME_BUF_BITS] frame_buf_reg;

reg     [2-1:0]                    state;
reg                                run;
reg                                freeze_stats;
reg                                frame_complete;
reg     [`REG_PKTS_BITS]           pkts;
reg     [`REG_OCTETS_BITS]         octets;
reg     [`REG_OCTETS_IDLE_BITS]    octets_idle;
reg     [`REG_TIMESTAMP_SEC_BITS]  timestamp_sec;
reg     [`REG_TIMESTAMP_NSEC_BITS] timestamp_nsec;
reg     [`REG_FRAME_SIZE_BITS]      frame_size;

reg     [7:0]   data;
wire    [`C_FRAME_BUF_ADDRESS_WIDTH-1:0]  frame_buf_out_address;
wire    [31:0]  frame_buf_out_data;
reg     [`C_FRAME_BUF_ADDRESS_WIDTH-1:0]  frame_buf_in_address;
reg     [31:0]  frame_buf_in_data;
reg             frame_buf_in_wr;
integer i;

//Registers section
traffic_analyzer_gmii_cpu_regs
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

        // statistics
        .pkts_reg (pkts_reg),
        .octets_reg (octets_reg),
        .octets_idle_reg (octets_idle_reg),

        // capture
        .timestamp_sec_reg(timestamp_sec_reg),
        .timestamp_nsec_reg(timestamp_nsec_reg),
        .frame_size_reg(frame_size_reg),
        .frame_buf_address(frame_buf_out_address),
        .frame_buf_data(frame_buf_out_data)
    );

bram_io #(
            .DATA_WIDTH(32),
            .ADDR_WIDTH(8) // 2048 bytes
        ) bram_io_inst (
            .rst(~resetn),

            .i_clk(clk),
            .i_wr(frame_buf_in_wr),
            .i_addr(frame_buf_in_address),
            .i_data(frame_buf_in_data),

            .o_clk(S_AXI_ACLK),
            .o_addr(frame_buf_out_address),
            .o_data(frame_buf_out_data)
        );

always @(posedge clk) begin

    run <= control_reg[0];
    freeze_stats <= control_reg[1];

    if(~resetn) begin
        state <= 2'b00;
        frame_size <= 0;
        pkts<= 0;
        octets <= 0;
        octets_idle <= 0;
        frame_complete <= 0;
        frame_buf_in_wr <= 0;
        frame_buf_in_address <= 0;

    end
    else begin
        case(state)
            2'b00 : begin
                if(gmii_en == 1'b1) begin
                    state <= 2'b01;
                    timestamp_sec <= sec;
                    timestamp_nsec <= nsec;
                    pkts <= pkts + 1;
                    data <= gmii_d;
                    frame_size <= 0;
                end
                else begin
                    octets_idle <= octets_idle + 1;
                end
                if(frame_complete & !freeze_stats) begin
                    frame_complete <= 0;
                    pkts_reg <= pkts;
                    octets_reg <= octets;
                    timestamp_sec_reg <= timestamp_sec;
                    timestamp_nsec_reg <= timestamp_nsec;
                    frame_size_reg <= frame_size;
                end
                frame_buf_in_wr <= 0;
            end
            2'b01 : begin
                frame_size <= frame_size + 1;
                octets <= octets + 1;
                if(gmii_en != 1'b1) begin
                    state <= 2'b00;
                    frame_complete <= 1;
                    octets_idle <= octets_idle + 1;
                    frame_buf_in_wr <= 0;
                end
                else begin
                    data <= gmii_d;
                end
                case(frame_size[1:0])
                    2'b00 : begin
                        frame_buf_in_data[31: 24] <= data;
                    end
                    2'b01 : begin
                        frame_buf_in_data[23: 16] <= data;
                    end
                    2'b10 : begin
                        frame_buf_in_data[15: 8] <= data;
                    end
                    2'b11 : begin
                        frame_buf_in_data[7: 0] <= data;
                    end
                endcase
                frame_buf_in_address <= frame_size/4;
                if(!freeze_stats) begin
                    frame_buf_in_wr <= 1;
                end
            end
        endcase
        if(!freeze_stats) begin
            octets_idle_reg <= octets_idle;
        end
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


endmodule
