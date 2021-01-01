`timescale 1ns/1ps
`include "ethernet_crc_8.v"

module ethernet_crc_8_check (
           input clk,
           input reset,
           input [8 - 1:0] d,
           input en,
           input er,
           output reg crc_ok,
           output reg preamble_ok
       );


reg      [1:0]   state;

reg         calc;
reg         init;
reg         d_valid;

//outputs
wire [31:0] crc_reg;
wire [7:0]  crc;

localparam [0:(8*8)-1] preamble = {8'h55,8'h55,8'h55,8'h55,8'h55,8'h55,8'h55,8'hd5};

reg [4:0] preamble_index;

reg [31:0] crc_history[0:5];
reg [31:0] d_history;

ethernet_crc_8 ethernet_crc_8_0 (.clk(clk), .reset(reset), .d(d), .calc(calc), .init(init), .d_valid(d_valid), .crc_reg(crc_reg), .crc(crc));

localparam [0:(8*8)-1] preamble0 = {8'h55,8'h55,8'h55,8'h55,8'h55,8'h55,8'h55,8'hd5}; //even octet alignment
localparam [0:(8*8)-1] preamble1 = {8'h55,8'h55,8'h55,8'h55,8'h55,8'h55,8'hd5}; //odd octet alignment

always @ (posedge clk or posedge reset)
begin
    if (reset) begin
        crc_ok <= 0;
        state <= 0;
    end

    else begin
        //$display("crc_reg=%x, crc=%x, d=%x, en=%x, calc=%x, init=%x, d_valid=%x, state=%x, reset=%x, d_history=%x, preamble_ok=%x, crc_ok=%x, preamble_index=%x", crc_reg, crc, d, en, calc, init, d_valid, state, reset, d_history, preamble_ok, crc_ok, preamble_index);
        case(state)
            2'b00 : begin
                crc_ok <= 0;
                preamble_ok <= 0;

                init <= 1;
                calc <= 0;
                d_valid <= 0;

                preamble_index <= 1;

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
                    preamble_ok <= 1;
                    state <= 2;
                    init <= 0;
                    calc <= 1;
                    d_valid <= 1;
                end
                preamble_index <= preamble_index + 1;
            end
            2'b10 : begin
                if(en == 0) begin
                    init <= 1;
                    calc <= 0;
                    d_valid <= 0;

                    if(crc_history[3] == d_history) begin
                        crc_ok <= 1;
                    end
                    state <= 0;

                end
                else begin
                    crc_history[3] <= crc_history[2];
                    crc_history[2] <= crc_history[1];
                    crc_history[1] <= crc_history[0];
                    crc_history[0] <= crc_reg;

                    d_history[31:24] <= d_history[23:16];
                    d_history[23:16] <= d_history[15:8];
                    d_history[15:8] <= d_history[7:0];
                    d_history[7] <= ~d[0];
                    d_history[6] <= ~d[1];
                    d_history[5] <= ~d[2];
                    d_history[4] <= ~d[3];
                    d_history[3] <= ~d[4];
                    d_history[2] <= ~d[5];
                    d_history[1] <= ~d[6];
                    d_history[0] <= ~d[7];
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
