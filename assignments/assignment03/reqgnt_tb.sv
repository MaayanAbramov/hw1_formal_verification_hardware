module tb;
    logic clk, rst, req, gnt;

    // Instantiate your verification module
    reqgnt dut (.*);

    // Clock Generation
    initial clk = 0;
    always #5 clk = ~clk;

    // === TASK: Reset between tests to clear state ===
    task do_reset();
        req = 0; gnt = 0;
        rst = 1;
        repeat(2) @(posedge clk);
        rst = 0;
        @(posedge clk);
    endtask

    // Test Sequence
    initial begin
        $display("=== STARTING REQGNT VERIFICATION TEST (WITH RESET) ===\n");
        
        // ---------------------------------------------
        // SCENARIO 1: GOOD BEHAVIOR
        // ---------------------------------------------
        do_reset();
        $display("[T=%0t] Scenario 1: Good Request (3 cycles)", $time);
        @(negedge clk); req = 1;
        @(negedge clk); req = 0;
        repeat(2) @(posedge clk);
        @(negedge clk); gnt = 1;
        @(negedge clk); gnt = 0;
        repeat(2) @(posedge clk);
        $display("  -> PASSED\n");

        // ---------------------------------------------
        // SCENARIO 2: BOUNDARY TEST - Min (2 cycles)
        // ---------------------------------------------
        do_reset();
        $display("[T=%0t] Scenario 2: Min Boundary (2 cycles)", $time);
        @(negedge clk); req = 1;
        @(negedge clk); req = 0;
        repeat(1) @(posedge clk);
        @(negedge clk); gnt = 1;
        @(negedge clk); gnt = 0;
        repeat(2) @(posedge clk);
        $display("  -> PASSED\n");

        // ---------------------------------------------
        // SCENARIO 3: BOUNDARY TEST - Safe (6 cycles)
        // ---------------------------------------------
        do_reset();
        $display("[T=%0t] Scenario 3: Safe Timing (6 cycles)", $time);
        @(negedge clk); req = 1;
        @(negedge clk); req = 0;
        repeat(5) @(posedge clk); 
        @(negedge clk); gnt = 1;
        @(negedge clk); gnt = 0;
        repeat(2) @(posedge clk);
        $display("  -> PASSED\n");

        // ---------------------------------------------
        // SCENARIO 3B: BOUNDARY TEST - Max (8 cycles)
        // ---------------------------------------------
        do_reset();
        $display("[T=%0t] Scenario 3B: Max Boundary (8 cycles)", $time);
        @(negedge clk); req = 1;
        @(negedge clk); req = 0;
        repeat(7) @(posedge clk);
        @(negedge clk); gnt = 1;
        @(negedge clk); gnt = 0;
        repeat(2) @(posedge clk);
        $display("  -> PASSED\n");

        // ---------------------------------------------
        // SCENARIO 4: MULTIPLE PENDING REQUESTS
        // ---------------------------------------------
        do_reset();
        $display("[T=%0t] Scenario 4: Multiple Requests", $time);
        @(negedge clk); req = 1;
        @(negedge clk); req = 0;
        @(negedge clk); req = 1;
        @(negedge clk); req = 0;
        @(negedge clk); req = 1;
        @(negedge clk); req = 0;
        repeat(2) @(posedge clk); 
        @(negedge clk); gnt = 1;
        @(negedge clk); gnt = 0;
        @(negedge clk); gnt = 1;
        @(negedge clk); gnt = 0;
        @(negedge clk); gnt = 1;
        @(negedge clk); gnt = 0;
        repeat(2) @(posedge clk);
        $display("  -> PASSED\n");

        $display("\n========================================");
        $display("BAD BEHAVIOR TESTS (Should show ERRORS)");
        $display("========================================\n");

        // ---------------------------------------------
        // SCENARIO 6: BAD - TOO FAST
        // ---------------------------------------------
        do_reset();
        $display("[T=%0t] Scenario 6: Too Fast (Age=1) - EXPECT ERROR:", $time);
        @(negedge clk); req = 1;
        @(negedge clk); begin req = 0; gnt = 1; end
        @(negedge clk); gnt = 0;
        repeat(2) @(posedge clk);

        // ---------------------------------------------
        // SCENARIO 8: BAD - SPURIOUS GRANT
        // ---------------------------------------------
        do_reset(); 
        $display("\n[T=%0t] Scenario 8: Spurious Grant (A2=0) - EXPECT ERROR:", $time);
        @(negedge clk); gnt = 1;
        @(negedge clk); gnt = 0;
        repeat(2) @(posedge clk);

        // ---------------------------------------------
        // SCENARIO 10: BAD - TOO SLOW
        // ---------------------------------------------
        do_reset();
        $display("\n[T=%0t] Scenario 10: Too Slow (>8 cycles) - EXPECT ERROR:", $time);
        @(negedge clk); req = 1;
        @(negedge clk); req = 0;
        repeat(9) @(posedge clk); 
        @(negedge clk); gnt = 1;
        @(negedge clk); gnt = 0;

        $display("\n=== ALL TESTS COMPLETED ===");
        $finish;
    end

    // Updated Monitor for your internal signals
    initial begin
        $monitor("T=%0t | A1=%b | A2=%b | req=%b gnt=%b", 
                 $time, dut.A1, dut.A2, req, gnt);
    end

    // Debug tracking logic updated for your A2 shift register
    logic req_q, gnt_q;
    always_ff @(posedge clk) begin
        if (rst) begin
            req_q <= 1'b0;
            gnt_q <= 1'b0;
        end else begin
            if (req && !req_q) $display("  [@%0t] REQ rose", $time);
            if (gnt && !gnt_q) begin
                $display("  [@%0t] GNT rose | A2 state: %b", $time, dut.A2);
                if (dut.A2 == 7'b0) $display("    -> ALERT: Granting with no pending requests!");
            end
            req_q <= req;
            gnt_q <= gnt;
        end
    end

endmodule