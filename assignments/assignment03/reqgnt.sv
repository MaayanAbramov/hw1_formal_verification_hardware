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
reg signed [3:0] cnt;
reg [0:1] A1;
reg [0:5] A2;

always @(posedge clk) 
begin
    if (rst) 
        begin
            cnt <= 4'b0000;
            A1 <= 2'b00;
            A2 <= 6'b000000;
        end 
    else
        begin
            if (req) A1[0] <= 1'b1;
            if (gnt) begin
                if (A2[5])      A2[5] <= 1'b0;
                else if (A2[4]) A2[4] <= 1'b0;
                else if (A2[3]) A2[3] <= 1'b0;
                else if (A2[2]) A2[2] <= 1'b0;
                else if (A2[1]) A2[1] <= 1'b0;
                else if (A2[0]) A2[0] <= 1'b0;
            end
            A2 <= (A2 >> 1);
            A2[0] <= A1[1];
            A1 <= (A1 >> 1);
        end
end

property P;
    @(posedge clk)
    (gnt |-> (A2 != 6'b000000)) and (!(!gnt && (A2[5] == 1'b1)));
endproperty

A: assert property (P);

endmodule