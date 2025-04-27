// ucsbece154_branch.v
// All Rights Reserved
// Copyright (c) 2024 UCSB ECE
// Distribution Prohibited


module ucsbece154b_branch #(
  parameter NUM_GHR_BITS    = 6
) (
  input               clk, // X
  input               reset_i, // X
  input        [31:0] pc_i, // X
  // input  [$clog2(NUM_BTB_ENTRIES)-1:0] BTBwriteaddress_i, // not used, pc_e[6:2]
  input        [31:0] BTBwritedata_i, // X PCTargetE
  output reg   [31:0] BTBtarget_o, // X
  // input               BTB_we, // not used, J_e | B_e
  output reg          BranchTaken_o, // X
  input         [6:0] branchop_i, // X
  input               PHTincrement_i, // X 
  input               GHRreset_i, // E, either caused by branch mispredict or F or D flushed
  input MisspredictE_i
  // input               PHTwe_i, // replaced by B_e
  // input    [NUM_GHR_BITS-1:0]  PHTwriteaddress_i,
  // output   [NUM_GHR_BITS-1:0]  PHTreadaddress_o
  // put mispredict logic on outside? have to pipeline branchtaken_o and compare with result in E stage
);

`include "ucsbece154b_defines.vh"

wire jumphit, branchhit, branchtaken_en; // F, need to implement output logic with these
reg [NUM_GHR_BITS-1:0] GHR ; // record of last 5 branch outcomes
reg B_type, J_type; // F, decoded instruction types
reg B_d, J_d; // D
reg B_e, J_e; // E
wire predict_taken; // F, predict taken or not for branch instructions
reg [NUM_GHR_BITS-1:0] PHTreadaddress; // F, XORed result of pc_i[6:2], GHR
wire [31:0] BTBtarget_internal; // F, next PC if branch predicted or jump

btb b0 (
  .clk(clk),
  .reset_i(reset_i),
  .pc_i(pc_i),
  .BTBwritedata_i(BTBwritedata_i), // E, new BTA data
  .J_i(J_e), // E, new J flag
  .B_i(B_e), // E, new B flag
  .BTBtarget_o(BTBtarget_internal), // F, next PC if branch predicted or jump
  .jumphit_o(jumphit), // is jump or not
  .branchhit_o(branchhit), // is branch or not
  .branchtaken_en(branchtaken_en), // branch cannot be predicted without valid BTA
  .PHTincrement_i(PHTincrement_i) // branch AND taken (for if statement of writing to BTB)
);

pht #(
  .NUM_GHR_BITS(NUM_GHR_BITS)
) p0 (
  .clk(clk),
  .reset_i(reset_i),
  .PHTreadaddress_o(PHTreadaddress),
  .PHTincrement_i(PHTincrement_i),
  .B_i(B_e),
  .predict_taken(predict_taken)
);

// misc. combo logic
always @(*) begin
  // decoder
  if (branchop_i == 7'd99) 
    B_type = 1'b1;
  else 
    B_type = 1'b0;
  if (branchop_i == 7'd103 || branchop_i == 7'd111)
    J_type = 1'b1;
  else
    J_type = 1'b0;
  // output logic
  BranchTaken_o = branchtaken_en & ((predict_taken & branchhit) | jumphit);
  PHTreadaddress = pc_i[NUM_GHR_BITS+1:2] ^ GHR;
  BTBtarget_o = BTBtarget_internal;
end

// GHR
always @(posedge clk or posedge reset_i) begin
  if (reset_i || GHRreset_i)
    GHR <= 0;
  else if (B_type)
    GHR <= {predict_taken, GHR[NUM_GHR_BITS-1:1]};
end

// misc. regs
always @(posedge clk or posedge reset_i or posedge MisspredictE_i or posedge GHRreset_i) begin
  if (reset_i) begin
    B_d <= 1'b0;
    B_e <= 1'b0;
    J_d <= 1'b0;
    J_e <= 1'b0;
  end
  else if (MisspredictE_i) begin
    B_d <= 1'b0;
    J_d <= 1'b0;
    B_e <= 1'b0;
    J_e <= 1'b0;
  end
  else if (GHRreset_i) begin
    B_d <= B_type;
    J_d <= J_type;
    B_e <= 1'b0;
    J_e <= 1'b0;
  end
  else begin
    B_d <= B_type;
    J_d <= J_type;
    B_e <= B_d;
    J_e <= J_d;
  end
end

endmodule
