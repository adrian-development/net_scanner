#!/bin/bash

#Zu bearbeitende Datei
filename="$1"

#Start Konsolenoutput
echo -e "\nStarting to Plot File ${filename}:"

#Entnehme alle Hosts aus erster Zeile, trenne erste Spalte da dort "Zeit" steht
HostList="$(head -n 1 "$filename" | cut -d ' ' -f 2- )"

#Debug, zeige Hostliste
echo Hosts: "$HostList"

#Start bei Spalte 2 da Spalte 1 für Zeiten
column_count=1

#Baue Kommando für Gnuplot
plot_arg="plot "
for host in $HostList
do
    ((column_count++))
    plot_arg="${plot_arg} \"$filename\" using 1:$column_count title \"$host\" with linespoints,"
done
#Debug, zeige Kommando
echo "$plot_arg"
echo "Spaltenzahl: $column_count"

#Erfasse Zeitrange, da gnuplot bei Zeiten auf x-Achse kein Autoscale verwenden kann
zeit_start=$(sed -n 2p "$filename" | cut -d ' ' -f 1)
zeit_end=$(tail -n 1 "$filename" | cut -d ' ' -f 1)
#Debug zeige Zeiten
echo "Start: $zeit_start Ende: $zeit_end"

#Vorverarbeitung, fülle leere Felder da gnuplot damit nicht umgehen kann
line_count=1

#Lese Datei line by line
while read -r line; do
    #Ermittle Spaltenzahl in dieser Zeile
    word_count=$( echo "$line" | wc -w)

    #Baue neue Zeile, füge fehlende Felder mit -100 ein
    while [[ $word_count < $column_count ]] ; do
        line=$( printf '%s%20s' "$line" "-100" )
        ((word_count++))
    done

    #Ersetze Zeile durch bearbeitete Zeile
    sed -i "${line_count}s/.*/$line/" "$filename"

    ((line_count++))
done < "$filename"


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

echo "Plot fertig"

exit 0

