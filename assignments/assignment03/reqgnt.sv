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
reg  A1;
reg [6:0] A2;

always @(posedge clk) begin
    if (rst) begin
        A1 <= 1'b0;
        A2 <= 7'b0000000;
    end else begin
        // ---- A1: 2-cycle request pipeline ----
        A1 <= req;

        // ---- A2: age pending requests ----
        A2 <= {A2[5:0], A1};

        // ---- Grant removes oldest pending request ----
        if (gnt) begin
            if      (A2[6]) A2[6] <= 1'b0;
            else if (A2[5]) A2[5] <= 1'b0;
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
    ((gnt |-> (A2 != 7'b0000000)) and (!(!gnt && (A2[6] == 1'b1))));
endproperty

A: assert property (P);


 //Assumes:(delete this)
//  reg gnt_without_req;
// reg unanswered_req;

// reg [9:0] unanswered_req_shift_reg;

// always_ff @(posedge clk or posedge rst) begin
//     if (rst) begin
//         gnt_without_req <= 0;
//         unanswered_req <= 0;
//         unanswered_req_shift_reg <= 0;
//     end else begin
//         logic matched_req;

//         unanswered_req_shift_reg = {unanswered_req_shift_reg[8:0], req};
//         matched_req = 0;

//         if (gnt) begin
//             for (int i = 8; i >= 2; i = i - 1) begin
//                 if (unanswered_req_shift_reg[i]) begin
//                     unanswered_req_shift_reg[i] = 0;
//                     matched_req = 1;
//                     break;
//                 end
//             end

//             if (!matched_req) begin
//                 gnt_without_req <= 1;
//             end
//         end

//         unanswered_req <= unanswered_req_shift_reg[9];
//     end
// end

// property P_1;
//     @(posedge clk) (!gnt_without_req) && (!unanswered_req);
// endproperty

// A_1: assume property (P_1);
endmodule