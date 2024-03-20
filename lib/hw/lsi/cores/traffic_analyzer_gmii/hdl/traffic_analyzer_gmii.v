`timescale 1ns/1ps
`include "traffic_analyzer_gmii_cpu_regs.v"
`include "traffic_analyzer_gmii_cpu_regs_defines.v"
`include "ethernet_crc_8_check.v"

`define C_GMII_DATA_WIDTH 8

module traffic_analyzer_gmii
       #(
           parameter C_S_AXI_DATA_WIDTH    = 32,
           parameter C_S_AXI_ADDR_WIDTH    = 12,
           parameter C_BASEADDR            = 32'h00000000,
           parameter C_FRAME_BUF_ADDRESS_WIDTH = 9
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
reg     [`REG_BAD_CRC_PKTS_BITS] bad_crc_pkts_reg;
reg     [`REG_BAD_CRC_OCTETS_BITS] bad_crc_octets_reg;
reg     [`REG_BAD_PREAMBLE_PKTS_BITS] bad_preamble_pkts_reg;
reg     [`REG_BAD_PREAMBLE_OCTETS_BITS] bad_preamble_octets_reg;
reg     [`REG_OCTETS_IDLE_BITS] octets_idle_reg;
reg     [`REG_OCTETS_TOTAL_BITS] octets_total_reg;
reg     [`REG_TIMESTAMP_SEC_BITS] timestamp_sec_reg;
reg     [`REG_TIMESTAMP_NSEC_BITS] timestamp_nsec_reg;
reg     [`REG_FRAME_SIZE_BITS] frame_size_reg;
reg     [`REG_FRAME_BUF_BITS] frame_buf_reg;

reg     [`REG_TESTFRAME_PKTS_BITS] testframe_pkts_reg;
reg     [`REG_SEQUENCE_ERRORS_BITS] sequence_errors_reg;
reg     [`REG_LATENCY_MAX_SEC_BITS] latency_max_sec_reg;
reg     [`REG_LATENCY_MAX_NSEC_BITS] latency_max_nsec_reg;
reg     [`REG_LATENCY_MIN_SEC_BITS] latency_min_sec_reg;
reg     [`REG_LATENCY_MIN_NSEC_BITS] latency_min_nsec_reg;
reg     [`REG_LATENCY_SEC_BITS] latency_sec_reg;
reg     [`REG_LATENCY_NSEC_BITS] latency_nsec_reg;


reg     [2-1:0]                    state;
reg                                run;
reg                                freeze_stats;
reg                                freeze_stats_sync; // synced to the first octet of the frame
reg                                update_latency; // second cycle of the pipeline updating the latency statistics
reg                                update_latency_regs;
reg                                frame_complete;
reg     [`REG_PKTS_BITS]           pkts;
reg     [`REG_OCTETS_BITS]         octets;
reg     [`REG_BAD_CRC_PKTS_BITS]           bad_crc_pkts;
reg     [`REG_BAD_CRC_OCTETS_BITS]         bad_crc_octets;
reg     [`REG_BAD_PREAMBLE_PKTS_BITS]      bad_preamble_pkts;
reg     [`REG_BAD_PREAMBLE_OCTETS_BITS]    bad_preamble_octets;
reg     [`REG_OCTETS_IDLE_BITS]    octets_idle;
reg     [`REG_OCTETS_TOTAL_BITS]    octets_total;
reg     [`REG_TIMESTAMP_SEC_BITS]  timestamp_sec;
reg     [`REG_TIMESTAMP_NSEC_BITS] timestamp_nsec;
reg     [`REG_FRAME_SIZE_BITS]      frame_size;
reg     [`REG_FRAME_SIZE_BITS]      l2_frame_size;

reg     [`REG_TESTFRAME_PKTS_BITS] testframe_pkts;
reg     [`REG_SEQUENCE_ERRORS_BITS] sequence_errors;
reg     [`REG_LATENCY_MIN_SEC_BITS] latency_min_sec;
reg     [`REG_LATENCY_MIN_NSEC_BITS] latency_min_nsec;
reg     [`REG_LATENCY_MAX_SEC_BITS] latency_max_sec;
reg     [`REG_LATENCY_MAX_NSEC_BITS] latency_max_nsec;

reg     [47:0] latency_sec;
reg     [31:0] latency_nsec;
wire    [47:0] timestamp_tx_sec;
wire    [31:0] timestamp_tx_nsec;
wire    [63:0] sequence_num;


reg     [7:0]   data;
wire    [C_FRAME_BUF_ADDRESS_WIDTH-1:0]  frame_buf_out_address;
wire    [31:0]  frame_buf_out_data;
reg     [C_FRAME_BUF_ADDRESS_WIDTH-1:0]  frame_buf_in_address;
reg     [31:0]  frame_buf_in_data;
reg             frame_buf_in_wr;
reg     [31:0]  expected_sequence_num;

wire [40*8-1:0] testframe_filter_data; //40 octet bitmask match filter
wire [40*8-1:0] testframe_filter_mask;


wire crc_ok;

integer i;
integer octets_delta;
integer pkts_delta;
integer bad_crc_octets_delta;
integer bad_crc_pkts_delta;
integer bad_preamble_octets_delta;
integer bad_preamble_pkts_delta;
integer testframe_pkts_delta;
integer sequence_errors_delta;


//Registers section
traffic_analyzer_gmii_cpu_regs
    #(
        .C_S_AXI_DATA_WIDTH (C_S_AXI_DATA_WIDTH),
        .C_S_AXI_ADDR_WIDTH (C_S_AXI_ADDR_WIDTH),
        .C_BASE_ADDRESS        (C_BASEADDR),
        .C_FRAME_BUF_ADDRESS_WIDTH(C_FRAME_BUF_ADDRESS_WIDTH)

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
        .testframe_filter_data_regs (testframe_filter_data),
        .testframe_filter_mask_regs (testframe_filter_mask),

        // statistics
        .pkts_reg (pkts_reg),
        .octets_reg (octets_reg),
        .bad_crc_pkts_reg (bad_crc_pkts_reg),
        .bad_crc_octets_reg (bad_crc_octets_reg),
        .bad_preamble_pkts_reg (bad_preamble_pkts_reg),
        .bad_preamble_octets_reg (bad_preamble_octets_reg),
        .octets_idle_reg (octets_idle_reg),
        .octets_total_reg (octets_total_reg),

        // capture
        .timestamp_sec_reg(timestamp_sec_reg),
        .timestamp_nsec_reg(timestamp_nsec_reg),
        .frame_size_reg(frame_size_reg),
        .frame_buf_address(frame_buf_out_address),
        .frame_buf_data(frame_buf_out_data),

         // stamped testframe stats
        .testframe_pkts_reg(testframe_pkts_reg),
        .sequence_errors_reg(sequence_errors_reg),
        .latency_max_sec_reg(latency_max_sec_reg),
        .latency_max_nsec_reg(latency_max_nsec_reg),
        .latency_min_sec_reg(latency_min_sec_reg),
        .latency_min_nsec_reg(latency_min_nsec_reg),
        .latency_sec_reg(latency_sec_reg),
        .latency_nsec_reg(latency_nsec_reg)
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

            .o_clk(S_AXI_ACLK),
            .o_addr(frame_buf_out_address),
            .o_data(frame_buf_out_data)
        );


ethernet_crc_8_check ethernet_crc_8_check_0 (
            .clk(clk),
            .reset(~resetn),
            .d(gmii_d),
            .en(gmii_en),
            .er(gmii_er),
            .crc_ok(crc_ok),
            .preamble_ok(preamble_ok));

testframe_parser testframe_parser_0 (
            .clk(clk),
            .reset(~resetn),
            .d(gmii_d),
            .en(gmii_en),
            .er(gmii_er),

            .testframe_filter_data(testframe_filter_data),
            .testframe_filter_mask(testframe_filter_mask),
            .testframe_match(testframe_match),
            .sequence_num(sequence_num),
            .timestamp_sec(timestamp_tx_sec),
            .timestamp_nsec(timestamp_tx_nsec));

always @(posedge clk) begin

    run <= control_reg[0];
    freeze_stats <= control_reg[1];

    if(~resetn || run==0) begin
        state <= 2'b00;
        frame_size <= 0;
        l2_frame_size <= 0;
        pkts<= 0;
        octets <= 0;
        bad_crc_pkts<= 0;
        bad_crc_octets <= 0;
        bad_preamble_pkts<= 0;
        bad_preamble_octets <= 0;
        octets_idle <= 0;
        octets_total <= 0;
        frame_complete <= 0;
        frame_buf_in_wr <= 0;
        frame_buf_in_address <= 0;
        freeze_stats_sync <= 0;

        testframe_pkts <= 0;
        sequence_errors <= 0;

        pkts_reg <= 0;
        octets_reg <= 0;
        bad_crc_pkts_reg <= 0;
        bad_crc_octets_reg <= 0;
        bad_preamble_pkts_reg <= 0;
        bad_preamble_octets_reg <= 0;
        octets_idle_reg <= 0;
        octets_total_reg <= 0;
        timestamp_sec_reg <= 0;
        timestamp_nsec_reg <= 0;
        frame_size_reg <= 0;

        testframe_pkts_reg <= 0;
        sequence_errors_reg <= 0;

        expected_sequence_num <= 0;


    end
    else begin
        case(state)
            2'b00 : begin
                if(gmii_en == 1'b1) begin
                    timestamp_sec <= sec;
                    timestamp_nsec <= nsec;
                    data <= gmii_d;
                    frame_size <= 0;
                    l2_frame_size <= 0;
                    state <= 1;
                    freeze_stats_sync <= freeze_stats;
                end
                if(frame_complete) begin
                    frame_complete <= 0;
                    frame_buf_in_wr <= 0;
                    frame_buf_in_address <= 0;

                    if(~preamble_ok) begin
                        octets_delta = 0;
                        pkts_delta = 0;
                        bad_crc_octets_delta = 0;
                        bad_crc_pkts_delta = 0;
                        bad_preamble_octets_delta = frame_size;
                        bad_preamble_pkts_delta = 1;
                        testframe_pkts_delta = 0;
                        sequence_errors_delta = 0;
                    end
                    else if(crc_ok) begin
                        octets_delta = l2_frame_size;
                        pkts_delta = 1;
                        bad_crc_octets_delta = 0;
                        bad_crc_pkts_delta = 0;
                        bad_preamble_octets_delta = 0;
                        bad_preamble_pkts_delta = 0;

                        if(testframe_match) begin
                            testframe_pkts_delta = 1;
                            if(sequence_num != expected_sequence_num) begin
                                sequence_errors_delta = 1;
                            end
                            else begin
                                sequence_errors_delta = 0;
                            end

                            expected_sequence_num <= sequence_num + 1;

                        end
                        else begin
                            testframe_pkts_delta = 0;
                            sequence_errors_delta = 0;
                        end
                    end
                    else begin
                        octets_delta = 0;
                        pkts_delta = 0;
                        bad_crc_octets_delta = l2_frame_size;
                        bad_crc_pkts_delta = 1;
                        bad_preamble_octets_delta = 0;
                        bad_preamble_pkts_delta = 0;
                        testframe_pkts_delta = 0;
                        sequence_errors_delta = 0;
                    end

                    octets <= octets + octets_delta;
                    pkts <= pkts + pkts_delta;

                    bad_crc_octets <= bad_crc_octets + bad_crc_octets_delta;
                    bad_crc_pkts <= bad_crc_pkts + bad_crc_pkts_delta;

                    bad_preamble_octets <= bad_preamble_octets + bad_preamble_octets_delta;
                    bad_preamble_pkts <= bad_preamble_pkts + bad_preamble_pkts_delta;

                    testframe_pkts <= testframe_pkts + testframe_pkts_delta;
                    sequence_errors <= sequence_errors + sequence_errors_delta;


                    if (!freeze_stats_sync) begin
                        pkts_reg <= pkts + pkts_delta;
                        octets_reg <= octets + octets_delta;
                        bad_crc_pkts_reg <= bad_crc_pkts + bad_crc_pkts_delta;
                        bad_crc_octets_reg <= bad_crc_octets + bad_crc_octets_delta;
                        bad_preamble_pkts_reg <= bad_preamble_pkts + bad_preamble_pkts_delta;
                        bad_preamble_octets_reg <= bad_preamble_octets + bad_preamble_octets_delta;
                        timestamp_sec_reg <= timestamp_sec;
                        timestamp_nsec_reg <= timestamp_nsec;
                        frame_size_reg <= frame_size;
                        testframe_pkts_reg <= testframe_pkts + testframe_pkts_delta;
                        sequence_errors_reg <= sequence_errors + sequence_errors_delta;
                    end
                end
            end
            2'b01 : begin
                frame_size <= frame_size + 1;
                if(preamble_ok && gmii_en) begin
                    l2_frame_size <= l2_frame_size + 1;
                end
                if(gmii_en != 1'b1) begin
                    state <= 2'b00;
                    frame_complete <= 1;
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
                frame_buf_in_wr <= !freeze_stats_sync;
            end
        endcase
        if(!gmii_en) begin
            octets_idle <= octets_idle + 1;
        end
        octets_total <= octets_total + 1;

        if(!freeze_stats) begin
            octets_idle_reg <= octets_idle;
            octets_total_reg <= octets_total;
        end
    end
end

always @(posedge clk) begin
    if(~resetn || run==0) begin
        latency_sec <= 0;
        latency_nsec <= 1;
        latency_min_sec <= 48'hFFFFFFFFFFFF;
        latency_min_nsec <= 32'hFFFFFFFF;
        latency_max_sec <= 0;
        latency_max_nsec <= 0;

        latency_sec_reg <= 0;
        latency_nsec_reg <= 2;
        latency_min_sec_reg <= 48'hFFFFFFFFFFFF;
        latency_min_nsec_reg <= 32'hFFFFFFFF;
        latency_max_sec_reg <= 0;
        latency_max_nsec_reg <= 0;

        update_latency <= 0;
        update_latency_regs <= 0;
    end
    else begin
        if(state == 0 && frame_complete && crc_ok && testframe_match) begin
            update_latency <= 1;
            if (!freeze_stats_sync) begin
                update_latency_regs <= 1;
            end

            //$display("Timestamp TX %018d.%09d", timestamp_tx_sec, timestamp_tx_nsec);
            //$display("Timestamp RX %018d.%09d", timestamp_sec, timestamp_nsec);

            //latency
            //$display("timestamp_nsec=%x, timestamp_tx_nsec=%x", timestamp_nsec, timestamp_tx_nsec);
            if(timestamp_nsec<timestamp_tx_nsec) begin
                latency_sec <= timestamp_sec - timestamp_tx_sec - 1;
                latency_nsec <= 32'd1000000000 - timestamp_tx_nsec + timestamp_nsec;
            end
            else begin
                latency_sec <= timestamp_sec - timestamp_tx_sec;
                latency_nsec <= timestamp_nsec - timestamp_tx_nsec;
            end
        end
        else begin
            if (update_latency) begin
                //if((latency_sec > latency_max_sec) || ((latency_sec == latency_max_sec) && (latency_nsec > latency_max_nsec))) begin
                if({latency_sec[47:0],latency_nsec[29:0]}>{latency_max_sec[47:0],latency_max_nsec[29:0]}) begin
                    latency_max_sec <= latency_sec;
                    latency_max_nsec <= latency_nsec;
                end
                //if((latency_sec < latency_min_sec) || ((latency_sec == latency_min_sec) && (latency_nsec < latency_min_nsec))) begin
                if({latency_sec[47:0],latency_nsec[29:0]}<{latency_min_sec[47:0],latency_min_nsec[29:0]}) begin
                    latency_min_sec <= latency_sec;
                    latency_min_nsec <= latency_nsec;
                end

                //$display("Latency %018d.%09d", latency_sec, latency_nsec);
                update_latency <= 0;
            end

            if (update_latency_regs) begin

                latency_sec_reg <= latency_sec;
                latency_nsec_reg <= latency_nsec;

                //if((latency_sec > latency_max_sec) || ((latency_sec == latency_max_sec) && (latency_nsec > latency_max_nsec))) begin
                if({latency_sec[47:0],latency_nsec[29:0]}>{latency_max_sec[47:0],latency_max_nsec[29:0]}) begin
                    latency_max_sec_reg <= latency_sec;
                    latency_max_nsec_reg <= latency_nsec;
                end
                else begin
                    latency_max_sec_reg <= latency_max_sec;
                    latency_max_nsec_reg <= latency_max_nsec;
                end
                //if((latency_sec < latency_min_sec) || ((latency_sec == latency_min_sec) && (latency_nsec < latency_min_nsec))) begin
                if({latency_sec[47:0],latency_nsec[29:0]}<{latency_min_sec[47:0],latency_min_nsec[29:0]}) begin
                    latency_min_sec_reg <= latency_sec;
                    latency_min_nsec_reg <= latency_nsec;
                end
                else begin
                    latency_min_sec_reg <= latency_min_sec;
                    latency_min_nsec_reg <= latency_min_nsec;
                end
                update_latency_regs <= 0;
            end
        end
    end
end


always @(posedge clk) begin
    if (~resetn) begin
        id_reg <= `REG_ID_DEFAULT;
        version_reg <= `REG_VERSION_DEFAULT;
        ip2cpu_flip_reg <= `REG_FLIP_DEFAULT;
    end
    else begin
        id_reg <= `REG_ID_DEFAULT;
        version_reg <= `REG_VERSION_DEFAULT;
        ip2cpu_flip_reg <= ~cpu2ip_flip_reg;
    end
end


endmodule
