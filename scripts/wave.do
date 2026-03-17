onerror {resume}
quietly WaveActivateNextPane {} 0

# ============================================================
#  GROUP 1 — Clock & Reset
# ============================================================
add wave -noupdate -divider {=== CLOCK / RESET ===}
add wave -noupdate -color Gold        -label "clk"       /elevator_tb/clk
add wave -noupdate -color OrangeRed   -label "rst"       /elevator_tb/rst

# ============================================================
#  GROUP 2 — Testbench stimulus
# ============================================================
add wave -noupdate -divider {=== STIMULUS ===}
add wave -noupdate -color Cyan        -label "floor_req [7:0]" \
    -radix binary                                         /elevator_tb/floor_req

# ============================================================
#  GROUP 3 — DUT outputs
# ============================================================
add wave -noupdate -divider {=== DUT OUTPUTS ===}
add wave -noupdate -color Chartreuse  -label "floor_pos"  \
    -radix unsigned                                       /elevator_tb/floor_pos
add wave -noupdate -color Yellow      -label "door_open"  /elevator_tb/door_open
add wave -noupdate -color SkyBlue     -label "moving_up"  /elevator_tb/moving_up
add wave -noupdate -color Plum        -label "moving_dn"  /elevator_tb/moving_down

# ============================================================
#  GROUP 4 — DUT internals
# ============================================================
add wave -noupdate -divider {=== DUT INTERNALS ===}

# FSM state — show as named enumeration
add wave -noupdate -color White       -label "state" \
    -radix symbolic                                       /elevator_tb/dut/state_q

# Pending request queue
add wave -noupdate -color Coral       -label "req_pending [7:0]" \
    -radix binary                                         /elevator_tb/dut/req_pending_q

# Door open counter
add wave -noupdate -color LightSalmon -label "door_cnt"  \
    -radix unsigned                                       /elevator_tb/dut/door_cnt_q

# Scan direction helpers
add wave -noupdate -color LightGreen  -label "req_above"  /elevator_tb/dut/req_above
add wave -noupdate -color LightBlue   -label "req_below"  /elevator_tb/dut/req_below

# Current direction memory
add wave -noupdate -color Violet      -label "dir_up"     /elevator_tb/dut/dir_up_q

# ============================================================
#  Waveform window layout
# ============================================================
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 1

configure wave -namecolwidth    200
configure wave -valuecolwidth   80
configure wave -justifyvalue    left
configure wave -signalnamewidth 1
configure wave -snapdistance    10
configure wave -datasetprefix   0
configure wave -rowmargin       4
configure wave -childrowmargin  2
configure wave -gridoffset      0
configure wave -gridperiod      10
configure wave -griddelta       40
configure wave -timeline        1
configure wave -timelineunits   ns

update
WaveRestoreZoom {0 ns} {200 ns}
