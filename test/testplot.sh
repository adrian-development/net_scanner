#!/bin/bash

FILE="ls.dat"

echo "Starte gnuplot"

gnuplot -persist <<PLOT

set xlabel "Zeit"
set ylabel "Ping"

plot "$FILE" using 1:2 title 'Removed' with lines,\
"$FILE" using 1:3 title 'Added' with lines,\
"$FILE" using 1:4 title 'Modified' with lines

PLOT
echo "Done ..."


exit 0