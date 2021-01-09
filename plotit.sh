#!/bin/bash

FILENAME="data"

echo start

gnuplot -p <<PLOT

plot "$FILENAME" using 1:2 title "NIC1" with lines,\
    "$FILENAME" using 1:3 title "NIC2" with lines,\
    "$FILENAME" using 1:4 title "NIC3" with lines
PLOT

echo finish

exit 0

