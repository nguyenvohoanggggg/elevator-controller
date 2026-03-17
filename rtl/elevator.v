// =============================================================================
// Module  : elevator
// Description:
//   N-floor elevator controller implementing the SCAN (elevator) algorithm.
//   Accepts a bitmask of floor requests (floor_req) and moves the cabin
//   floor-by-floor each clock cycle, keeping the current travel direction
//   until no more requests exist in that direction before reversing.
//
//   FSM states:
//     IDLE — no pending requests; waiting for input
//     UP   — moving upward one floor per clock cycle
//     DOWN — moving downward one floor per clock cycle
//     DOOR — door open; counter counts DOOR_OPEN cycles before closing
//
// Parameters:
//   FLOORS    — total number of floors (default 8); POS_W auto-derived
//   DOOR_OPEN — number of clock cycles the door stays open (default 5)
//
// Outputs:
//   floor_pos   — current floor index (0-based, unsigned)
//   door_open   — high while door is open (STATE_DOOR)
//   moving_up   — high while cabin is ascending
//   moving_down — high while cabin is descending
// =============================================================================
module elevator #(
    parameter integer FLOORS    = 8,
    parameter integer DOOR_OPEN = 5
    )(
    input wire clk,
    input wire rst,
    input wire [FLOORS-1:0] floor_req,          // bitmask floor requests
    output wire [$clog2(FLOORS)-1:0] floor_pos,  // current floor (driven via floor_pos_q)
    output reg door_open,
    output reg moving_up,
    output reg moving_down
    );

    // Derive position width from FLOORS
    localparam integer POS_W = $clog2(FLOORS);

    // Internal floor position register; exposed via continuous assign
    reg [POS_W-1:0] floor_pos_q;
    assign floor_pos = floor_pos_q;

    // STATE
    localparam [2:0] STATE_IDLE = 3'd0;
    localparam [2:0] STATE_UP   = 3'd1;
    localparam [2:0] STATE_DOWN = 3'd2;
    localparam [2:0] STATE_DOOR = 3'd3;

    reg [2:0] state_q, state_d;
    reg [FLOORS-1:0] req_pending_q, req_pending_d;
    reg dir_up_q, dir_up_d;
    reg [POS_W-1:0] floor_pos_d;

    //  door open time counter bit-width (number of bits, not a count value)
    localparam integer DOOR_CNT_W = (DOOR_OPEN <= 1) ? 1 : $clog2(DOOR_OPEN);

    reg [DOOR_CNT_W-1:0] door_cnt_q, door_cnt_d;

    // Scan direction elevator
    function [1:0] scan_above_below;
        input [FLOORS-1:0] pending;
        input [POS_W-1:0] current;
        integer i;
        reg req_above;
        reg req_below;
        begin
            req_above = 1'b0;
            req_below = 1'b0;
            for (i = 0;i < FLOORS;i = i + 1) begin
                if ((i > current) && (pending[i])) req_above = 1'b1;
                if ((i < current) && (pending[i])) req_below = 1'b1;
            end
            scan_above_below = {req_above,req_below};
        end
    endfunction

    //decode function scan_above_below
    reg req_above;
    reg req_below;
    reg [1:0] scan_dir;

    reg [POS_W-1:0] next_pos;

    //  Combinational logic
    always @(*) begin
    // Defaults
    state_d = state_q;
    door_cnt_d = door_cnt_q;
    dir_up_d = dir_up_q;
    floor_pos_d = floor_pos_q;
    next_pos = floor_pos_q;

    req_pending_d = req_pending_q | floor_req;

    if (state_q == STATE_DOOR) begin
        if(floor_pos_q < FLOORS)
            req_pending_d[floor_pos_q] = 1'b0;
    end

    scan_dir = scan_above_below(req_pending_d,floor_pos_q);
    req_above = scan_dir[1];
    req_below = scan_dir[0];

    case (state_q)
        STATE_IDLE: begin
            door_cnt_d = {DOOR_CNT_W{1'b0}};

                // request at current floor -> open door
                if ((floor_pos_q < FLOORS) && req_pending_d[floor_pos_q]) begin
                    state_d    = STATE_DOOR;
                    door_cnt_d = {DOOR_CNT_W{1'b0}};
                end
                else if (req_above && !req_below) begin
                    state_d  = STATE_UP;
                    dir_up_d = 1'b1;
                end
                else if (!req_above && req_below) begin
                    state_d  = STATE_DOWN;
                    dir_up_d = 1'b0;
                end
                else if (req_above && req_below) begin
                    state_d = (dir_up_q) ? STATE_UP : STATE_DOWN;
                end
                else begin
                    state_d = STATE_IDLE;
                end
            end

            // UP STATE
            STATE_UP: begin
                // move up one floor per cycle
                if (floor_pos_q < (FLOORS-1)) begin
                    next_pos   = floor_pos_q + 1'b1;
                    floor_pos_d = next_pos;

                    // If a request exists at the arrived floor, open the door immediately
                    if ((next_pos < FLOORS) && req_pending_d[next_pos]) begin
                        state_d    = STATE_DOOR;
                        door_cnt_d = {DOOR_CNT_W{1'b0}};
                        dir_up_d   = 1'b1;
                    end
                end else begin
                    state_d = STATE_IDLE;   // already at top floor
                end
            end

            // DOWN STATE
            STATE_DOWN: begin
                // move down one floor per cycle, if not at bottom
                if (floor_pos_q > 0) begin
                    next_pos    = floor_pos_q - 1'b1;
                    floor_pos_d = next_pos;

                    // If a request exists at the arrived floor, open the door immediately
                    if ((next_pos < FLOORS) && req_pending_d[next_pos]) begin
                        state_d    = STATE_DOOR;
                        door_cnt_d = {DOOR_CNT_W{1'b0}};
                        dir_up_d   = 1'b0;
                    end
                end else begin
                    state_d = STATE_IDLE;   // already at bottom floor
                end
            end

            // OPEN DOOR STATE
            STATE_DOOR: begin
                if (DOOR_OPEN <= 1) begin   // case special
                    // special case: 1 cycle open
                    door_cnt_d = {DOOR_CNT_W{1'b0}};

                    // choose next direction based on remaining pending
                    if (req_above && !req_below) begin
                        state_d  = STATE_UP;  dir_up_d = 1'b1;
                    end else if (!req_above && req_below) begin
                        state_d  = STATE_DOWN;  dir_up_d = 1'b0;
                    end else if (req_above && req_below) begin
                        state_d = (dir_up_q) ? STATE_UP : STATE_DOWN;
                    end else begin
                        state_d = STATE_IDLE;
                    end
                end
                else begin
                    // normal counter mode
                    // if current floor is pressed again, restart the door timer
                    if ((floor_pos_q < FLOORS) && floor_req[floor_pos_q]) begin
                        door_cnt_d = {DOOR_CNT_W{1'b0}};
                    end
                    else if (door_cnt_q >= (DOOR_OPEN-1)) begin
                        door_cnt_d = {DOOR_CNT_W{1'b0}};

                        if (req_above && !req_below) begin
                            state_d  = STATE_UP;  dir_up_d = 1'b1;
                        end else if (!req_above && req_below) begin
                            state_d  = STATE_DOWN;  dir_up_d = 1'b0;
                        end else if (req_above && req_below) begin
                            state_d = (dir_up_q) ? STATE_UP : STATE_DOWN;
                        end else begin
                            state_d = STATE_IDLE;
                        end
                    end
                    else begin
                        door_cnt_d = door_cnt_q + {{(DOOR_CNT_W-1){1'b0}},1'b1};
                    end
                end
            end

            default: begin
                state_d = STATE_IDLE;
            end
        endcase
    end

    // Sequential logic
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            state_q       <= STATE_IDLE;
            req_pending_q <= {FLOORS{1'b0}};
            floor_pos_q   <= {POS_W{1'b0}};
            door_cnt_q    <= {DOOR_CNT_W{1'b0}};
            dir_up_q      <= 1'b1;
        end
        else begin
            state_q       <= state_d;
            req_pending_q <= req_pending_d;
            floor_pos_q   <= floor_pos_d;
            door_cnt_q    <= door_cnt_d;
            dir_up_q      <= dir_up_d;
        end
    end

    // Parameter sanity checks (elaboration-time)
    initial begin
        if (FLOORS < 2)
            $fatal(1, "elevator: FLOORS must be >= 2, got %0d", FLOORS);
        if (DOOR_OPEN < 1)
            $fatal(1, "elevator: DOOR_OPEN must be >= 1, got %0d", DOOR_OPEN);
        if ((1 << POS_W) < FLOORS)
            $fatal(1, "elevator: POS_W=%0d too narrow for FLOORS=%0d", POS_W, FLOORS);
    end

    //  Outputs
    always @(*) begin
        door_open = (state_q == STATE_DOOR);
        moving_up = (state_q == STATE_UP);
        moving_down = (state_q == STATE_DOWN);
    end
endmodule