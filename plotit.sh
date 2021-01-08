#!/bin/bash

gnuplot -p <<PLOT

plot "data" using 1:2 title "NIC1" with lines,\
    "data" using 1:3 title "NIC2" with lines,\
    "data" using 1:4 title "NIC3" with lines
PLOT

pause -1


exit 0

