module fifo #(
  parameter int unsigned DEPTH = 64,
  parameter int unsigned WIDTH = 64
) (
  input  logic                  clk,
  input  logic                  rst,
  input  logic                  enq_valid,
  output logic                  enq_ready,
  input  logic [WIDTH-1:0]      enq_data,
  output logic                  deq_valid,
  input  logic                  deq_ready,
  output logic [WIDTH-1:0]      deq_data,
  output logic                  full,
  output logic                  empty
);

  localparam int unsigned PTRW = (DEPTH <= 1) ? 1 : $clog2(DEPTH);

  logic [WIDTH-1:0] mem [0:DEPTH-1];
  logic [PTRW-1:0]  wr_ptr, rd_ptr;
  logic [PTRW:0]    count;

  logic do_enq, do_deq;

  assign empty     = (count == 0);
  assign full      = (count == DEPTH);
  assign enq_ready = !full;
  assign deq_valid = !empty;

  assign do_enq = enq_valid && enq_ready;
  assign do_deq = deq_valid && deq_ready;

  always_ff @(posedge clk or negedge rst) begin
    if (!rst) begin
      wr_ptr   <= '0;
      rd_ptr   <= '0;
      count    <= '0;
      deq_data <= '0;
    end else begin
      if (do_enq) begin
        mem[wr_ptr] <= enq_data;
        wr_ptr      <= (wr_ptr == DEPTH-1) ? '0 : wr_ptr + 1'b1;
      end
      if (do_deq) begin
        deq_data <= mem[rd_ptr];
        rd_ptr   <= (rd_ptr == DEPTH-1) ? '0 : rd_ptr + 1'b1;
      end
      unique case ({do_enq, do_deq})
        2'b10: count <= count + 1'b1;
        2'b01: count <= count - 1'b1;
        default: ;
      endcase
    end
  end

// IMPLEMENT THE AUXILIARY CODE HERE
wire select; 

reg [WIDTH-1:0] sampled_data;
reg [PTRW : 0] items_ahead;
reg is_sampled;

always @(posedge clk) 
begin
  if (!rst) 
    begin
      is_sampled <= 1'b0;
      items_ahead <= '0;
      sampled_data <= '0;
    end
  else
    begin
      if (do_enq && !is_sampled && select && !(do_deq && count == 0))
        begin
          sampled_data <= enq_data;
          items_ahead <= do_deq ? (count - 1'b1) : count; // CHANGED HERE
          is_sampled <= 1'b1;
        end
      else if (is_sampled && do_deq) // CHANGED HERE
        begin
          if(items_ahead > 0)
            begin
              items_ahead <= items_ahead - 1'b1;
            end
          else
            begin
              is_sampled <= 1'b0;
            end
        end
    end
end

property P;
    @(posedge clk) disable iff (!rst) (is_sampled && (items_ahead == 0) && do_deq) |=> (deq_data == sampled_data); // CHANGED HERE
endproperty

A: assert property (P);

endmodule