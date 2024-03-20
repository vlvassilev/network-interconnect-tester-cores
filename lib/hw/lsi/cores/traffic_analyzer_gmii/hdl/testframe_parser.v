`timescale 1ns/1ps

module testframe_parser (
           input clk,
           input reset,
           input [8 - 1:0] d,
           input en,
           input er,
           input [40*8-1:0] testframe_filter_data, //40 octet bitmask match filter
           input [40*8-1:0] testframe_filter_mask,
           output reg testframe_match,
           output reg [63:0] sequence_num,
           output reg [47:0] timestamp_sec,
           output reg [31:0] timestamp_nsec
       );


reg      [1:0]   state;

localparam [0:(8*8)-1] preamble = {8'h55,8'h55,8'h55,8'h55,8'h55,8'h55,8'h55,8'hd5};


reg [4:0] preamble_index;
reg [12:0]  data_index;
reg [7:0] testframe_mismatch;

reg [7:0] testframe_history[0:21];

integer i;

localparam [0:(8*8)-1] preamble0 = {8'h55,8'h55,8'h55,8'h55,8'h55,8'h55,8'h55,8'hd5}; //even octet alignment
localparam [0:(8*8)-1] preamble1 = {8'h55,8'h55,8'h55,8'h55,8'h55,8'h55,8'hd5}; //odd octet alignment

always @ (posedge clk or posedge reset)
begin
    if (reset) begin
        state <= 0;
        testframe_match <= 0;
        sequence_num <= 0;
        timestamp_sec <= 0;
        timestamp_nsec <= 0;
        testframe_mismatch <= 0;
    end

    else begin
        case(state)
            2'b00 : begin
                testframe_match <= 0;
                sequence_num <= 0;
                timestamp_sec <= 0;
                timestamp_nsec <= 0;

                preamble_index <= 1;
                data_index <= 0;
                testframe_mismatch <= 0;

                if(en == 1) begin
                    if(d == 8'h55) begin
                        state <= 1;
                    end
                    else begin
                        state <= 3;
                    end
                end
            end
            2'b01 : begin
                if (en == 0) begin
                    state <= 0;
                end
                else if ((d != 8'h55) && (d != 8'hd5)) begin
                    state <= 3; // bad preamble - unexpected octet
                end
                else if ((preamble_index<6) && (d==8'hd5)) begin
                    state <= 3; // bad preamble - too early
                end
                else if ((preamble_index>=7) && (d==8'h55)) begin
                    state <= 3; // bad preamble
                end
                else if(d == 8'hd5) begin
                    // preamble ok
                    state <= 2;
                end
                preamble_index <= preamble_index + 1;
            end

            2'b10 : begin
                if(en == 0) begin
                    sequence_num[63:56] <= testframe_history[21];
                    sequence_num[55:48] <= testframe_history[20];
                    sequence_num[47:40] <= testframe_history[19];
                    sequence_num[39:32] <= testframe_history[18];
                    sequence_num[31:24] <= testframe_history[17];
                    sequence_num[23:16] <= testframe_history[16];
                    sequence_num[15:8]  <= testframe_history[15];
                    sequence_num[7:0]   <= testframe_history[14];

                    timestamp_sec[47:40] <= testframe_history[13];
                    timestamp_sec[39:32] <= testframe_history[12];
                    timestamp_sec[31:24] <= testframe_history[11];
                    timestamp_sec[23:16] <= testframe_history[10];
                    timestamp_sec[15:8]  <= testframe_history[9];
                    timestamp_sec[7:0]   <= testframe_history[8];

                    timestamp_nsec[31:24] <= testframe_history[7];
                    timestamp_nsec[23:16] <= testframe_history[6];
                    timestamp_nsec[15:8]  <= testframe_history[5];
                    timestamp_nsec[7:0]   <= testframe_history[4];

                    state <= 0;

                end
                else begin
                    testframe_history[0] <= d;
                    for(i=0;i<21;i=i+1) begin
                        testframe_history[i+1] <= testframe_history[i];
                    end

                    data_index <= data_index + 1;
                    if(data_index==37 && d==7 && testframe_history[0]==0) begin
                        testframe_match <= 1;
                    end

                    for(i=0;i<40;i=i+1) begin
                        if(i==data_index) begin
                            testframe_mismatch <= testframe_mismatch | ((testframe_filter_data[8*0+7:8*0] ^ d) & testframe_filter_mask[8*0+7:8*0]);
                        end
                    end
//                    if(data_index==40 && testframe_mismatch==0) begin
//                        testframe_match <= 1;
//                    end
                end
            end
            2'b11 : begin
                if (en == 0) begin
                    state <= 0;
                end
            end
        endcase
   end
end

endmodule

