`timescale 1ns/1ps
module tb;

localparam CLK_PERIOD_NS=8;

//inputs
reg clk;
reg rst;
reg  [7:0]  d;
reg         calc;
reg         init;
reg         d_valid;

//outputs
wire [31:0] crc_reg;
wire [7:0]  crc;

integer i;
integer j;
integer len;
reg [7:0] data;
reg [7:0] frame [0:1530];

ethernet_crc_8 ethernet_crc_8_0 (.clk(clk), .reset(rst), .d(d), .calc(calc), .init(init), .d_valid(d_valid), .crc_reg(crc_reg), .crc(crc));

always #(CLK_PERIOD_NS / 2) clk = ~clk;

always @(posedge clk) begin
    $display("time=%t, d=%x, crc_reg=%x, crc=%x, d_valid=%x, calc=%x, init=%x", $time, d, crc_reg, crc, d_valid, calc, init);
end

initial begin
    clk = 0;
    rst = 0;
    d = 0;
    init = 0;
    d_valid = 0;

    $display("Reading frame ...");
    len = 64+8; // frame includes layer1 preamble 55555555555555d5
    $readmemh("frame.mem", frame, 0, len-1);

    #(10*CLK_PERIOD_NS) rst = 1;

    #(10*CLK_PERIOD_NS) rst = 0;

    #(1*CLK_PERIOD_NS);
    init = 1;
    d_valid=0;
    calc=0;
    d = 0;
    for (i = 8; i < len-4; i = i + 1) begin
        #(1*CLK_PERIOD_NS);
        data = frame[i];
        d = data;
        init = 0;
        d_valid = 1;
        calc = 1;
    end

    for (j = 0; j < 4; j = j + 1) begin
        #(1*CLK_PERIOD_NS);
        calc = 0;
        if(crc != frame[len-4+j]) begin
            $error("Bad crc frame[%d]==%x expected %x", len-4+j, frame[len-4+j], crc);
            $fatal;

        end
        $display("Good crc frame[%d]==%x expected %x", len-4+j, frame[len-4+j], crc);
    end

    #(1*CLK_PERIOD_NS);
    d_valid = 0;
    calc = 0;

    $finish;

end

endmodule

