#!/bin/bash

FILENAME="scan.dat"

echo start
plot_arg="plot "
#Start bei Spalte 2 da Spalte 1 für Zeiten
column_count=2

HostList="$(head -n 1 $FILENAME | cut -d ' ' -f 2- )"
echo $HostList

for host in $HostList
do
    plot_arg="${plot_arg} \"$FILENAME\" using 1:$column_count title \"$host\" with lines,"
    ((column_count++))
done

echo "$plot_arg"


gnuplot -p <<PLOT
$plot_arg
#plot "$FILENAME" using 1:2 title "NIC1" with lines, "$FILENAME" using 1:3 title "NIC2" with lines, "$FILENAME" using 1:4 title "NIC3" with lines
PLOT

echo finish

exit 0

