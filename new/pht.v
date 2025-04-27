module pht #(
  parameter NUM_GHR_BITS    = 5
) (
  input clk,
  input reset_i,
  input [NUM_GHR_BITS-1:0] PHTreadaddress_o,
  input PHTincrement_i,
  input B_i,
  output wire predict_taken
);

  localparam NUM_PHT_ENTRIES = 2 ** NUM_GHR_BITS;

  reg [1:0] PHT [NUM_PHT_ENTRIES-1:0];
  reg [NUM_GHR_BITS-1:0] PHTwriteaddress_d;
  reg [NUM_GHR_BITS-1:0] PHTwriteaddress_e;
  integer i;

  // PHT regs
  always @(posedge clk or posedge reset_i) begin
    if (reset_i) begin
      for (i = 0; i < NUM_PHT_ENTRIES; i = i + 1) begin
        PHT[i] <= 2'b00;
      end
    end else begin // write PHT entry
      if (B_i) begin
        case (PHTincrement_i)
          1'b0 : begin
            if (PHT[PHTwriteaddress_e] != 2'b00)
              PHT[PHTwriteaddress_e] <= PHT[PHTwriteaddress_e] - 1;
          end
          1'b1 : begin
            if (PHT[PHTwriteaddress_e] != 2'b11) 
              PHT[PHTwriteaddress_e] <= PHT[PHTwriteaddress_e] + 1;
          end
        endcase
      end
    end
  end

    // internal regs
  always @(posedge clk or posedge reset_i) begin
    if (reset_i) begin
      PHTwriteaddress_d <= 5'b00000;
      PHTwriteaddress_e <= 5'b00000;
    end else begin
      PHTwriteaddress_d <= PHTreadaddress_o;
      PHTwriteaddress_e <= PHTwriteaddress_d;
    end
  end

  assign predict_taken = PHT[PHTreadaddress_o][1];

endmodule
