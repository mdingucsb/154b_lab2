// ucsbece154b_riscv_pipe.v
// ECE 154B, RISC-V pipelined processor 
// All Rights Reserved
// Copyright (c) 2024 UCSB ECE
// Distribution Prohibited


module ucsbece154b_riscv_pipe (
    input               clk, reset,
    output wire  [31:0] PCF_o,
    input        [31:0] InstrF_i,
    output wire         MemWriteM_o,
    output wire  [31:0] ALUResultM_o,
    output wire  [31:0] WriteDataM_o,
    input        [31:0] ReadDataM_i
);

wire StallF, StallD, RegWriteW, FlushE, ALUSrcE, ZeroE;
wire [6:0] op;
wire [2:0] funct3;
wire funct7b5;
wire [2:0] ImmSrcD;
wire [2:0] ALUControlE;
wire [1:0] ForwardAE, ForwardBE, ResultSrcW, ResultSrcM;
wire [4:0] Rs1D, Rs2D, Rs1E, Rs2E, RdE, RdM, RdW;

wire PHTincrement;
wire GHRreset;
wire JumpE;

wire [31:0] BTBwritedata;
wire BranchTaken;
wire [31:0] BTBtarget;
wire [31:0] PCF;
wire [6:0] branchop;

assign PCF_o = PCF;

  ucsbece154b_controller c (
      .clk(clk), .reset(reset),
      .op_i (op), 
      .funct3_i(funct3),
      .funct7b5_i(funct7b5),
      .ZeroE_i(ZeroE),
      .Rs1D_i(Rs1D),
      .Rs2D_i(Rs2D),
      .Rs1E_i(Rs1E),
      .Rs2E_i(Rs2E),
      .RdE_i(RdE),
      .RdM_i(RdM),
      .RdW_i(RdW),
      .StallF_o(StallF),  
      .StallD_o(StallD),
      .ImmSrcD_o(ImmSrcD),
      .ALUControlE_o(ALUControlE),
      .ALUSrcE_o(ALUSrcE),
      .FlushE_o(FlushE),
      .ForwardAE_o(ForwardAE),
      .ForwardBE_o(ForwardBE),
      .MemWriteM_o(MemWriteM_o),
      .RegWriteW_o(RegWriteW),
      .ResultSrcW_o (ResultSrcW),
      .ResultSrcM_o (ResultSrcM),
      .PHTincrement_o (PHTincrement),
      .JumpE_o (JumpE)
  );


  ucsbece154b_datapath dp (
      .clk(clk), .reset(reset),
      .StallF_i(StallF),
      .PCF_o(PCF),
      .StallD_i(StallD),
      .InstrF_i(InstrF_i),
      .op_o(op),
      .funct3_o(funct3),
      .funct7b5_o(funct7b5),
      .RegWriteW_i(RegWriteW),
      .ImmSrcD_i(ImmSrcD),
      .Rs1D_o(Rs1D),
      .Rs2D_o(Rs2D),
      .FlushE_i(FlushE),
      .Rs1E_o(Rs1E),
      .Rs2E_o(Rs2E), 
      .RdE_o(RdE), 
      .ALUSrcE_i(ALUSrcE),
      .ALUControlE_i(ALUControlE),
      .ForwardAE_i(ForwardAE),
      .ForwardBE_i(ForwardBE),
      .ZeroE_o(ZeroE),
      .RdM_o(RdM), 
      .ALUResultM_o(ALUResultM_o),
      .WriteDataM_o(WriteDataM_o),
      .ReadDataM_i(ReadDataM_i),
      .ResultSrcW_i(ResultSrcW),
      .RdW_o(RdW),
      .ResultSrcM_i (ResultSrcM),
      .PCTargetE_o (BTBwritedata),
      .BranchTaken_i (BranchTaken),
      .BTBtarget_i (BTBtarget),
      .GHRreset_o (GHRreset),
      .PHTincrement_i (PHTincrement),
      .JumpE_i (JumpE),
      .branchop_o (branchop)
  );

  ucsbece154b_branch b (
    .clk(clk), .reset_i(reset),
    .pc_i (PCF),
    .BTBwritedata_i (BTBwritedata),
    .BTBtarget_o (BTBtarget),
    .BranchTaken_o (BranchTaken),
    .branchop_i (branchop),
    .PHTincrement_i (PHTincrement),
    .GHRreset_i (GHRreset)
  );


endmodule
