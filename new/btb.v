module btb #(
  parameter NUM_BTB_ENTRIES = 32 // NUM_BTB_ENTRIES was 32
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

  localparam LOG2_BTB = $clog2(NUM_BTB_ENTRIES); // 3 for BTB8

  reg [31-2-LOG2_BTB:0] Tag [NUM_BTB_ENTRIES-1:0]; // 26:0, 2:0
  reg [31:0] Target [NUM_BTB_ENTRIES-1:0];
  reg        J [NUM_BTB_ENTRIES-1:0];
  reg        B [NUM_BTB_ENTRIES-1:0];
  reg        cache_hit;
  reg [31:0] pc_d; // d stage pc
  reg [31:0] pc_e; // e stage pc, used for BTA
  reg        cache_hit_d;
  reg        cache_hit_e;
  reg        BTB_write;
  wire [LOG2_BTB-1:0] btb_index;
  assign btb_index = pc_i[LOG2_BTB+1:2];
  integer i;

  always @(*) begin 
    if ((Tag[btb_index] == pc_i[31:LOG2_BTB+2]) && (J[btb_index] || B[btb_index])) begin
      cache_hit = 1'b1; 
      branchtaken_en = 1'b1;
    end else begin
      cache_hit = 1'b0;
      branchtaken_en = 1'b0;
    end
    BTB_write = (!cache_hit_e && (J_i || PHTincrement_i));
  end

  // if cache hit, async read
  always @(*) begin
    if (cache_hit) begin
      BTBtarget_o = Target[btb_index];
      jumphit_o   = J[btb_index];
      branchhit_o = B[btb_index];
    end else begin
      BTBtarget_o = 32'b0;
      jumphit_o   = 1'b0;
      branchhit_o = 1'b0;
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
        Tag[i] <= 0;
        Target[i] <= 0;
        J[i] <= 1'b0;
        B[i] <= 1'b0;
      end
    end else begin
      if (BTB_write) begin
        Tag[pc_e[LOG2_BTB+1:2]] <= pc_e[31:LOG2_BTB+2];
        Target[pc_e[LOG2_BTB+1:2]] <= BTBwritedata_i;
        J[pc_e[LOG2_BTB+1:2]] <= J_i;
        B[pc_e[LOG2_BTB+1:2]] <= B_i;
      end
    end
  end

endmodule
