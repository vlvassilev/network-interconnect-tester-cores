module cocotb_iverilog_dump();
initial begin
    $dumpfile("sim_build/tester_loop.fst");
    $dumpvars(0, tester_loop);
end
endmodule
