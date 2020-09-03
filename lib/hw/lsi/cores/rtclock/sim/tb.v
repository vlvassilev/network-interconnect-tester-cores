`timescale 1ns/1ps

module tb;

  localparam CLK_PERIOD_NS=110000000;

  reg clk;
  reg resetn;
  wire [47:0] o_sec;
  wire [29:0] o_nsec;
  time       cur_time;

  reg [47:0] sec;
  reg [29:0] nsec;

  rtclock #( CLK_PERIOD_NS ) dut1 (clk, resetn, o_sec, o_nsec);

  always #(CLK_PERIOD_NS / 2) clk = ~clk;

  always @(posedge clk) begin
           sec = o_sec;
           nsec = o_nsec;
           cur_time = $time;
           $display("time=%t sec=%d,  nsec=%d, resetn=%d", cur_time, sec, nsec, resetn);
           if($time != 0 & $time != (sec*1000000000 + nsec + 2*CLK_PERIOD_NS)) begin
               $error("Error time=%t != %d", $time, (sec*1000000000 + nsec + 2*CLK_PERIOD_NS));
               $fatal;
           end
  end

  initial begin
     clk = 1;
     resetn = 1;

     #(1*CLK_PERIOD_NS) resetn = 0;

     #(1*CLK_PERIOD_NS) resetn = 1;

     wait (sec[3]);

     $finish;

  end

endmodule
