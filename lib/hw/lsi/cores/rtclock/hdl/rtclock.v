`timescale 1ns/1ps

module rtclock
#(
    parameter C_CLK_TO_NS_RATIO    = 8

)
(
    input clk,
    input resetn,

    output reg [47:0] sec,
    output reg [29:0] nsec
);

    parameter nsec_modulo = 31'd1000000000;

    reg sec_inc = 0;
 
    always @(posedge clk) begin
        if (~resetn) begin
            sec <= 0;
            nsec <= 0;
            sec_inc <= 0;
        end
        else begin
            sec_inc = (nsec >= (nsec_modulo-C_CLK_TO_NS_RATIO))? 1'b1: 1'b0;
            if(sec_inc) begin
                sec <= sec + 1;
                nsec <= nsec - (nsec_modulo-C_CLK_TO_NS_RATIO);
            end
            else begin
                nsec <= nsec + C_CLK_TO_NS_RATIO;
            end
        end
    end

endmodule
