`timescale 1ns/1ps
`include "ethernet_crc_8.v"

module ethernet_crc_8_check (
           input clk,
           input reset,
           input [8 - 1:0] d,
           input en,
           input er,
           output reg crc_ok
       );


reg      [1:0]   state;

reg         calc;
reg         init;
reg         d_valid;

//outputs
wire [31:0] crc_reg;
wire [7:0]  crc;

localparam [0:(8*8)-1] preamble = {8'h55,8'h55,8'h55,8'h55,8'h55,8'h55,8'h55,8'hd5};

reg [7:0] preamble_expected;
reg [4:0] preamble_index_next;

reg [31:0] crc_history[0:5];
reg [31:0] d_history;

ethernet_crc_8 ethernet_crc_8_0 (.clk(clk), .reset(reset), .d(d), .calc(calc), .init(init), .d_valid(d_valid), .crc_reg(crc_reg), .crc(crc));

always @ (posedge clk or posedge reset)
begin
    if (reset) begin
        crc_ok <= 0;
        state <= 0;
    end

    else begin
        //$display("crc_reg=%x, crc=%x, d=%x, en=%x, calc=%x, init=%x, d_valid=%x, state=%x, preamble_expected=%x, reset=%x, d_history=%x", crc_reg, crc, d, en, calc, init, d_valid, state, preamble_expected, reset, d_history);
        case(state)
            2'b00 : begin
                crc_ok <= 0;

                init <= 1;
                calc <= 0;
                d_valid <= 0;

                if(en == 1 && d == 8'h55) begin
                    state <= 1;
                    preamble_expected <= preamble[0*8+:8];
                    preamble_index_next <= 2;
                end
            end
            2'b01 : begin
                if(en == 0 || d != preamble_expected) begin
                    state <= 0;
                end
                else if(preamble_index_next==8) begin
                    state <= 2;
                    init <= 0;
                    calc <= 1;
                    d_valid <= 1;
                end
                else begin
                    preamble_expected <= preamble[preamble_index_next*8+:8];
                    preamble_index_next <= preamble_index_next + 1;
                end
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
        endcase
   end
end

endmodule
