module reqgnt(
    input logic clk,
    input logic rst,
    input logic req,
    input logic gnt
);

// Instructions:
// 1. Implement "property P;" below.
// 2. Use auxiliary code.
// 3. Do not change the name of the property (keep it "P").
// 4. Do not change the label of the assert (keep it "A").

// IMPLEMENT THE AUXILIARY CODE HERE

// count number of open reqs
ralways @(posedge clk) begin
    if (rst) begin
        A1 <= 2'b00;
        A2 <= 6'b000000;
    end else begin
        // ---- A1: 2-cycle request pipeline ----
        A1[0] <= req;
        A1[1] <= A1[0];

        // ---- A2: age pending requests ----
        A2 <= {A2[4:0], A1[1]};

        // ---- Grant removes oldest pending request ----
        if (gnt) begin
            if      (A2[5]) A2[5] <= 1'b0;
            else if (A2[4]) A2[4] <= 1'b0;
            else if (A2[3]) A2[3] <= 1'b0;
            else if (A2[2]) A2[2] <= 1'b0;
            else if (A2[1]) A2[1] <= 1'b0;
            else if (A2[0]) A2[0] <= 1'b0;
        end
    end
end


property P;
    @(posedge clk)
    ((gnt |-> (A2 != 6'b000000)) and (!(!gnt && (A2[5] == 1'b1))));
endproperty

A: assert property (P);

endmodule