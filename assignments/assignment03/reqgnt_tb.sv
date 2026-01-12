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
        // Grant exactly 3 cycles after the request (inclusive window is 2..8).
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
        // Grant exactly 2 cycles after the request (minimum allowed).
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
        // Grant exactly 8 cycles after the request (maximum allowed).
        repeat(7) @(posedge clk);
        @(negedge clk); gnt = 1;
        @(negedge clk); gnt = 0;
        repeat(2) @(posedge clk);
        $display("  -> PASSED\n");

        // ---------------------------------------------
        // SCENARIO 4: MULTIPLE PENDING REQUESTS (Fixed)
        // ---------------------------------------------
        do_reset();
        $display("[T=%0t] Scenario 4: Multiple Requests", $time);
        // Send 3 requests
        @(negedge clk); req = 1;
        @(negedge clk); req = 0;
        @(negedge clk); req = 1;
        @(negedge clk); req = 0;
        @(negedge clk); req = 1;
        @(negedge clk); req = 0;
        
        repeat(2) @(posedge clk); // Wait only 2 cycles to avoid timeout
        
        // Grant back-to-back
        @(negedge clk); gnt = 1;
        @(negedge clk); gnt = 0;
        @(negedge clk); gnt = 1;
        @(negedge clk); gnt = 0;
        @(negedge clk); gnt = 1;
        @(negedge clk); gnt = 0;
        
        repeat(2) @(posedge clk);
        $display("  -> PASSED\n");

        // ---------------------------------------------
        // SCENARIO 5: SIMULTANEOUS REQ & GNT
        // ---------------------------------------------
        do_reset();
        $display("[T=%0t] Scenario 5: Concurrent Req & Gnt", $time);
        @(negedge clk); req = 1;
        @(negedge clk); req = 0;
        repeat(2) @(posedge clk);
        @(negedge clk); req = 1; gnt = 1; // Simultaneous rise at next posedge
        @(negedge clk); req = 0; gnt = 0;
        repeat(2) @(posedge clk);
        @(negedge clk); gnt = 1;
        @(negedge clk); gnt = 0;
        repeat(2) @(posedge clk);
        $display("  -> PASSED\n");

        $display("\n========================================");
        $display("BAD BEHAVIOR TESTS (Should show ERRORS)");
        $display("========================================\n");

	// ---------------------------------------------
        // SCENARIO 6: BAD - TOO FAST with cnt=1 (Expect Error)
        // ---------------------------------------------
        do_reset();
        $display("[T=%0t] Scenario 6: Too Fast (cnt=1) - EXPECT ERROR NOW:", $time);
    // Force an illegal 1-cycle delay:
    // - req rises at the next posedge
    // - gnt rises at the *following* posedge (age=1)
    @(negedge clk); req = 1;
    @(negedge clk); begin req = 0; gnt = 1; end
    @(negedge clk); gnt = 0;
        repeat(2) @(posedge clk);

        // ---------------------------------------------
        // SCENARIO 7: BAD - TOO SLOW with Multiple Pending (Expect Error)
        // ---------------------------------------------
        do_reset();
        $display("\n[T=%0t] Scenario 7: Too Slow with Multiple Pending (cnt>1) - EXPECT ERROR:", $time);
        // Two pending requests, then we intentionally starve the head past 8 cycles.
        @(negedge clk); req = 1;
        @(negedge clk); req = 0;
        @(negedge clk); req = 1;
        @(negedge clk); req = 0;
        repeat(10) @(posedge clk); // Should trigger MAX delay violation before any grant

        // ---------------------------------------------
        // SCENARIO 8: BAD - SPURIOUS GRANT with cnt=0 (Expect Error)
        // ---------------------------------------------
        do_reset(); // Reset clears cnt to 0!
        $display("\n[T=%0t] Scenario 8: Spurious Grant (cnt=0) - EXPECT ERROR NOW:", $time);
        @(negedge clk); gnt = 1;
        @(negedge clk); gnt = 0;
        repeat(2) @(posedge clk);

        // ---------------------------------------------
        // SCENARIO 9: BAD - Grant when cnt>1 but wrong timing (Expect Error)
        // ---------------------------------------------
        do_reset();
        $display("\n[T=%0t] Scenario 9: Multiple Pending, Second Grant Too Fast - EXPECT ERROR:", $time);
        // Goal: Make Grant1 legal for Req1, then introduce Req2 so that Grant2 happens
        // only 1 cycle after Req2's rising edge (age=1 => illegal).

        // 1) Req1 becomes old enough.
        @(negedge clk); req = 1;
        @(negedge clk); req = 0;
        repeat(3) @(posedge clk);

        // 2) Grant Req1 legally.
        @(negedge clk); gnt = 1;
        @(negedge clk); gnt = 0;

        // 3) Issue Req2 so it rises at the next posedge.
        @(negedge clk); req = 1;
        // 4) On the following negedge (after Req2 rose), arm a grant so it rises at the
        //    next posedge: Req2 age will be 1 there (illegal).
        @(negedge clk); begin req = 0; gnt = 1; end
        @(negedge clk); gnt = 0;
        repeat(2) @(posedge clk);
        
        // ---------------------------------------------
        // SCENARIO 10: BAD - TOO SLOW (Expect Error)
        // ---------------------------------------------
        do_reset();
        $display("\n[T=%0t] Scenario 10: Too Slow (>8 cycles) - EXPECT ERROR NOW:", $time);
        @(negedge clk); req = 1;
        @(negedge clk); req = 0;
        repeat(9) @(posedge clk); // Too long
        @(negedge clk); gnt = 1;
        @(negedge clk); gnt = 0;

        // ---------------------------------------------
        // SCENARIO 11: BAD - REQ & GNT same cycle on EMPTY (Expect Error)
        // This is the classic hole if you only use a counter with 2'b11 => no change.
        // Spec requires gnt to be 2..8 cycles AFTER the req, so same-cycle is illegal.
        // ---------------------------------------------
        do_reset();
        $display("\n[T=%0t] Scenario 11: Same-cycle Req+Gnt with cnt=0 - EXPECT ERROR NOW:", $time);
        @(negedge clk); req = 1; gnt = 1;
        @(negedge clk); req = 0; gnt = 0;
        repeat(2) @(posedge clk);
        
        $display("\n=== ALL TESTS COMPLETED ===");
        $finish;
    end

    // Monitor for debugging
    initial begin
        $monitor("T=%0t | cnt=%0d | fifo=%0d | req=%b gnt=%b", 
                 $time, dut.cnt, dut.fifo_count, req, gnt);
    end

    // Event-focused debug: show exactly when edges happen and what the checker sees.
    // Note: This samples DUT state in the Active region at posedge (pre-NBA), which is
    // the "pre-update" state used by the assertions in reqgnt.sv.
    logic req_q, gnt_q;
    always_ff @(posedge clk) begin
        if (rst) begin
            req_q <= 1'b0;
            gnt_q <= 1'b0;
        end else begin
            bit req_rose;
            bit gnt_rose;
            req_rose = (req && !req_q);
            gnt_rose = (gnt && !gnt_q);

            if (req_rose) begin
                $display("  [@%0t] REQ rose", $time);
            end

            if (gnt_rose) begin
                int fc;
                int rdp;
                int ct;
                int head_t;
                int age;
                fc = dut.fifo_count;
                rdp = dut.rd_ptr;
                ct = dut.current_time;
                head_t = dut.arrival_mem[rdp];
                age = ct - head_t;
                $display("  [@%0t] GNT rose | pre: fifo=%0d rd_ptr=%0d time=%0d head_time=%0d age=%0d (need 2..8)",
                         $time, fc, rdp, ct, head_t, age);
            end

            req_q <= req;
            gnt_q <= gnt;
        end
    end

endmodule

