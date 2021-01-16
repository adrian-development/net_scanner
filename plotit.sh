#!/bin/bash

#Konstante
FILENAME="scan.dat"

#Start Konsolenoutput
echo Starting to Plot File

#Entnehme alle Hosts aus erster Zeile, trenne erste Spalte da dort "Zeit" steht
HostList="$(head -n 1 $FILENAME | cut -f 2- )"

#Debug, zeige Hostliste
echo Hosts: $HostList

#Start bei Spalte 2 da Spalte 1 für Zeiten
column_count=2

#Baue Kommando für Gnuplot
plot_arg="plot "
for host in $HostList
do
    plot_arg="${plot_arg} \"$FILENAME\" using 1:$column_count title \"$host\" with linespoints,"
    ((column_count++))
done
#Debug, zeige Kommando
echo "$plot_arg"


#Erfasse Zeitrange, da gnuplot bei Zeiten auf x-Achse kein Autoscale verwenden kann
zeit_start=$(sed -n 2p $FILENAME | cut -f 1)
zeit_end=$(tail -n 1 $FILENAME | cut -f 1)
#Debug zeige Zeiten
echo Start: $zeit_start Ende: $zeit_end

#"Präprozessor", fülle leere Felder da gnuplot damit nicht umgehen kann




#Parametrisiere Gnuplot mit HERE Dokument und obigem Kommando
gnuplot -p <<PLOT
set title "Netzwerkmonitor"
set xlabel "Uhrzeit"
set ylabel "Ping in ms"
set yrange [-200:1000]
set xdata time
set timefmt "%H:%M:%S"
set format x "%H:%M:%S"
set xrange ["$zeit_start":"$zeit_end"]
$plot_arg
PLOT

echo Fertig

exit 0

