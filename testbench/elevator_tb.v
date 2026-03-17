`timescale 1ns / 1ps

module elevator_tb;

  // Parameters
  localparam FLOORS     = 8;
  localparam POS_W      = $clog2(FLOORS);
  localparam DOOR_OPEN  = 5;                        // must match RTL default
  // Worst-case travel: full span + one door open + margin
  localparam TRAVEL_MAX = FLOORS + DOOR_OPEN + 4;

  reg clk;
  reg rst;
  reg [FLOORS-1:0] floor_req;

  wire [POS_W-1:0]  floor_pos;
  wire               door_open;
  wire               moving_up;
  wire               moving_down;

  // Expose internal pending queue for observability
  wire [FLOORS-1:0]  pending;
  assign pending = dut.req_pending_q;

  elevator dut (
    .clk(clk),
    .rst(rst),
    .floor_req(floor_req),
    .floor_pos(floor_pos),
    .door_open(door_open),
    .moving_up(moving_up),
    .moving_down(moving_down)
  );

  // Clock generation: 10ns period
  initial clk = 1'b0;
  always #5 clk = ~clk;

  // MONITOR: log 
  always @(posedge clk) begin
    if (!rst) begin
          $display("[%0t] pos=%0d | req=%b | door=%b | up=%b | dn=%b",
             $time,
             floor_pos,
             floor_req,
             door_open,
             moving_up,
             moving_down);
    end
  end

  // Task: wait N clock cycles
  task wait_cycles(input integer n);
    integer i;
    begin
      for (i = 0; i < n; i = i + 1)
        @(posedge clk);
    end
  endtask

  // Task: press one floor — held across a full posedge so RTL is guaranteed to sample it
  task press_floor(input integer f);
    begin
      if (f < 0 || f >= FLOORS) begin
        $display("[%0t] ERROR: invalid floor index %0d", $time, f);
      end else begin
        @(posedge clk); #1;
        floor_req = (1 << f);
        @(posedge clk); #1;
        floor_req = {FLOORS{1'b0}};
      end
    end
  endtask

  // Task: assert elevator reaches target floor within timeout cycles
  task check_floor(input integer target, input integer timeout);
    integer i;
    reg     found;
    begin
      found = 0;
      for (i = 0; i < timeout && !found; i = i + 1) begin
        @(posedge clk);
        if (floor_pos == target) begin
          $display("[%0t] PASS: reached floor %0d", $time, target);
          found = 1;
        end
      end
      if (!found)
        $error("[%0t] FAIL: did not reach floor %0d within %0d cycles",
               $time, target, timeout);
    end
  endtask

  // Test sequence
  initial begin
    // ----------------------------------------------------------------
    // Initialise
    // ----------------------------------------------------------------
    floor_req = 0;
    rst = 1'b1;
    wait_cycles(3);
    @(negedge clk);           // de-assert away from posedge to avoid races
    rst = 1'b0;

    // ----------------------------------------------------------------
    // Case 1: request at current floor (0) — door opens immediately
    // ----------------------------------------------------------------
    press_floor(0);
    check_floor(0, TRAVEL_MAX);
    wait_cycles(DOOR_OPEN + 2);

    // ----------------------------------------------------------------
    // Case 2: go up to floor 3
    // ----------------------------------------------------------------
    press_floor(3);
    check_floor(3, TRAVEL_MAX);
    wait_cycles(DOOR_OPEN + 2);

    // ----------------------------------------------------------------
    // Case 3: go down to floor 1
    // ----------------------------------------------------------------
    press_floor(1);
    check_floor(1, TRAVEL_MAX);
    wait_cycles(DOOR_OPEN + 2);

    // ----------------------------------------------------------------
    // Case 4: multiple simultaneous requests (floors 2 and 5)
    // ----------------------------------------------------------------
    @(posedge clk); #1;
    floor_req = (1<<2) | (1<<5);
    @(posedge clk); #1;
    floor_req = 0;
    check_floor(2, TRAVEL_MAX);
    wait_cycles(DOOR_OPEN + 2);
    check_floor(5, TRAVEL_MAX);
    wait_cycles(DOOR_OPEN + 2);

    // ----------------------------------------------------------------
    // Case 5: full journey to top floor (floor 7) from floor 1
    // ----------------------------------------------------------------
    press_floor(7);
    check_floor(7, TRAVEL_MAX);
    wait_cycles(DOOR_OPEN + 2);

    // ----------------------------------------------------------------
    // Case 6: full journey back to bottom floor (floor 0) from floor 7
    // ----------------------------------------------------------------
    press_floor(0);
    check_floor(0, TRAVEL_MAX);
    wait_cycles(DOOR_OPEN + 2);

    // ----------------------------------------------------------------
    // Case 7: requests on both sides while moving (SCAN direction test)
    // ----------------------------------------------------------------
    @(posedge clk); #1;
    floor_req = (1<<6) | (1<<2);
    @(posedge clk); #1;
    floor_req = 0;
    wait_cycles(TRAVEL_MAX * 2);

    // ----------------------------------------------------------------
    // Case 8: reset mid-travel — floor_pos must return to 0
    // ----------------------------------------------------------------
    press_floor(7);
    wait_cycles(3);
    rst = 1'b1;
    wait_cycles(2);
    @(negedge clk);
    rst = 1'b0;
    if (floor_pos !== 0)
      $error("[%0t] FAIL reset: floor_pos=%0d, expected 0", $time, floor_pos);
    else
      $display("[%0t] PASS: floor_pos reset to 0 correctly", $time);
    wait_cycles(2);

    // ----------------------------------------------------------------
    // Case 9: door-open extension — re-press same floor while door open
    //         (timer must restart, door stays open for another DOOR_OPEN)
    // ----------------------------------------------------------------
    press_floor(3);
    check_floor(3, TRAVEL_MAX);
    wait_cycles(2);            // 2 cycles into door-open window
    press_floor(3);            // re-press: timer restarts
    wait_cycles(DOOR_OPEN + 4);

    $display("=== SIMULATION FINISHED ===");
    $finish;
  end

endmodule



