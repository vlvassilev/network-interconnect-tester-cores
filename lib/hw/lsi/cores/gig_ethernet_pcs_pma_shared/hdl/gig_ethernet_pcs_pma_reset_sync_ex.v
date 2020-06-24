`timescale 1ps/1ps

module gig_ethernet_pcs_pma_reset_sync_ex #(
  parameter INITIALISE = 2'b11
)
(
   input       reset_in,
   input       clk,
   output      reset_out
);


  wire  reset_stage1;
  wire  reset_stage2;
  wire  reset_stage3;
  wire  reset_stage4;
  wire  reset_stage5;
  wire  reset_stage6;

  (* shreg_extract = "no", ASYNC_REG = "TRUE" *)
  FDP #(
   .INIT (INITIALISE[0])
  ) reset_sync1 (
  .C  (clk), 
  .PRE(reset_in),
  .D  (1'b0),
  .Q  (reset_stage1) 
  );
  
  (* shreg_extract = "no", ASYNC_REG = "TRUE" *)
  FDP #(
   .INIT (INITIALISE[1])
  ) reset_sync2 (
  .C  (clk), 
  .PRE(reset_in),
  .D  (reset_stage1),
  .Q  (reset_stage2) 
  );

  (* shreg_extract = "no", ASYNC_REG = "TRUE" *)
  FDP #(
   .INIT (INITIALISE[1])
  ) reset_sync3 (
  .C  (clk), 
  .PRE(reset_in),
  .D  (reset_stage2),
  .Q  (reset_stage3) 
  );

  (* shreg_extract = "no", ASYNC_REG = "TRUE" *)
  FDP #(
   .INIT (INITIALISE[1])
  ) reset_sync4 (
  .C  (clk), 
  .PRE(reset_in),
  .D  (reset_stage3),
  .Q  (reset_stage4) 
  );

  (* shreg_extract = "no", ASYNC_REG = "TRUE" *)
  FDP #(
   .INIT (INITIALISE[1])
  ) reset_sync5 (
  .C  (clk), 
  .PRE(reset_in),
  .D  (reset_stage4),
  .Q  (reset_stage5) 
  );

  (* shreg_extract = "no", ASYNC_REG = "TRUE" *)
  FDP #(
   .INIT (INITIALISE[1])
  ) reset_sync6 (
  .C  (clk), 
  .PRE(1'b0),
  .D  (reset_stage5),
  .Q  (reset_stage6) 
  );

assign reset_out = reset_stage6;



endmodule
