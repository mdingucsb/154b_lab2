`timescale 1ns / 1ps

module btb #(
  parameter NUM_BTB_ENTRIES = 32
) (
  input clk,
  input reset_i,
  input [31:0] pc_i, // f 
  input [31:0] BTBwritedata_i, // e, for BTA
  input J_i, // e, for J
  input B_i, // e, for B
  output reg [31:0] BTBtarget_o, // f
  output reg jumphit_o, // f, stays in branch predictor
  output reg branchhit_o, // f, stays in branch predictor
  output reg branchtaken_en, // f, stays in branch predictor
  input PHTincrement_i // e, for BTB write condition
);

  reg [24:0] Tag [NUM_BTB_ENTRIES-1:0];
  reg [31:0] Target [NUM_BTB_ENTRIES-1:0];
  reg        J [NUM_BTB_ENTRIES-1:0];
  reg        B [NUM_BTB_ENTRIES-1:0];
  reg        cache_hit;
  reg [31:0] pc_d; // d stage pc
  reg [31:0] pc_e; // e stage pc, used for BTA
  reg        cache_hit_d;
  reg        cache_hit_e;
  reg        BTB_write;
  integer i;

  // determine if cache hit, if not force predict not taken (since no BTA ready)
  always @(*) begin 
    cache_hit = 1'b0;
    branchtaken_en = 1'b0;
    for (i = 0; i < NUM_BTB_ENTRIES; i = i + 1) begin
      if (pc_i[31:7] == Tag[i] && (J[pc_i[6:2]] || B[pc_i[6:2]])) begin //match tag AND index's B or J must be 1
        cache_hit = 1'b1; 
        branchtaken_en = 1'b1; // allow possibility of branch taken prediction (since branch predict cannot predict Y without BTA)
      end
    end
    BTB_write = (!cache_hit_e && (J_i || PHTincrement_i));
  end

  // if cache hit, async read
  always @(*) begin 
    for (i = 0; i < NUM_BTB_ENTRIES; i = i + 1) begin
      if (cache_hit) begin
        BTBtarget_o = Target[pc_i[6:2]];
        jumphit_o = J[pc_i[6:2]];
        branchhit_o = B[pc_i[6:2]];
      end else begin
        BTBtarget_o = 32'b0;
        jumphit_o = 1'b0;
        branchhit_o = 1'b0;
      end
    end
  end

  // internal regs
  always @(posedge clk or posedge reset_i) begin
    if (reset_i) begin
      pc_d <= 32'b0;
      pc_e <= 32'b0;
      cache_hit_d <= 1'b1; // since condition is LOW enable, default is HIGH
      cache_hit_e <= 1'b1; // since condition is LOW enable, default is HIGH
    end else begin
      pc_d <= pc_i;
      pc_e <= pc_d;
      cache_hit_d <= cache_hit;
      cache_hit_e <= cache_hit_d;
    end
  end

  // memory regs
  always @(posedge clk or posedge reset_i) begin 
    if (reset_i) begin // reset
      for (i = 0; i < NUM_BTB_ENTRIES; i = i + 1) begin
        Tag[i] <= 25'b0;
        Target[i] <= 32'b0;
        J[i] <= 1'b0;
        B[i] <= 1'b0;
      end
    end else begin
      if (BTB_write) begin
        Tag[pc_e[6:2]] <= pc_e[31:7];
        Target[pc_e[6:2]] <= BTBwritedata_i;
        J[pc_e[6:2]] <= J_i;
        B[pc_e[6:2]] <= B_i;
      end
    end
  end

endmodule

