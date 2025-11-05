G21         ; set units to mm
G90         ; absolute positioning
G0 Z5       ; move to safe height
G0 X6.25 Y-1 ; move above start of slot
S10000

G1 Z-0.5 F50  ; plunge at 50 mm/min
G1 Y1 F50    ; cut along Y to end of slot at 100 mm/min
G1 Z-1 F50
G1 Y-1 F50
G1 Z-1.5 F50
G1 Y1 F50
G1 Z-2 F50
G1 Y-1 F50

G0 Z5
G0 X-6.25 Y-1 F50
G1 Z-0.5 F50
G1 Y1 F50
G1 Z-1 F50
G1 Y-1 F50
G1 Z-1.5 F50
G1 Y1 F50
G1 Z-2 F50
G1 Y-1 F50
G0 Z5

G0 X0 Y0      ; return to home
M30           ; end of program

