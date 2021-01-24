#!/bin/bash
#----------------------------------------------------------
#    File-name: netmonitor.sh
#     Language: bash script
#     Synopsis: netmonitor.sh [-p|--ping hosts] [-h|--help] [-i|--intervall wartezeit] [-a|--auswertung filename]
#  Description: Ein tool zur Analyse des lokalen Netzwerks
#      Project: Shell Script Programming Course
#       Author: jaegerad74878@th-nuernberg.de
#----------------------------------------------------------

#Variablen initialisieren
scan_mode=1
intervall=10
filename=
IP_list=
first_line=
OutputLine=
network="--localnet"
interface=""


#Help Funktion
function help ()
{
    cat <<HELPTEXT
NAME
    netmonitor.sh
    Nimmt eine Analyse Ihres Netzwerks vor.

SYNOPSIS
    netmonitor.sh [-h|--help] [-p|--ping hosts] [-d|--delay wartezeit] [-i|--interface Netzwerkschnittstelle] 
        [-n|--network Netzwerkadresse] [-a|--auswertung filename]

DESCRIPTION
    Netmonitor ermittelt über einen ARP-Scan zyklisch sämtliche Geräte in Ihrem IPv4 Netzwerkes und pingt dieses an
    um die performance über längere Zeitabschnitte zu protokollieren. Die Messdaten werden in einer separaten Datei
    gespeichert und nach Ende des Scans graphisch dargestellt.
    Die Messung wird durch STRG+C gestoppt. Werte von -100 in der Auswertung stehen für einen Timeout beim Ping.

OPTIONS
    --help | -h
        Zeigt diese Seite

    --ping | -p
        Erlaubt eine beliebig lange Liste an Hosts zum erfassen hinzuzufügen. Es können sowohl URLs als 
        auch IP-Adressen durche Leerzeichen getrennt angegeben werden.

    --delay | -d
        Legt die Wartezeit zwischen zwei Messungen in Sekunden fest. Nur Ganzzahlen erlaubt.

    --interface | -i
        Legt das zu verwendende Netzwerkinterface für den ARP-Scan fest. z.B. "eth0"
    
    --network | -n 
        Legt das zu Scannende Netzwerk im Format "Netzwerkadresse/Subnetzmaske" fest, z.B. "192.168.178.0/24"

    --auswertung | -a
        Nimmt ausschließlich eine Auswertung der angegebenen Logdatei vor.
    
EXAMPLES
    netmonitor.sh
        Startet die Aufzeichung mit Standardverzögerung von 10 Sekunden im Automatisch ermittelten Netzwerk und mit
        dem am höchsten priorisierten Netzwerkinterface.

    netmonitor.sh --ping www.google.de 141.75.201.12 --delay 20
        Pingt zusätzliche google und die genannte IP alle 20 Sekunden an.

    netmonitor.sh --auswertung scan_2021-01-17.dat
        Startet keinen Scan sondern wertet eine bereits erstellt Datei aus.

    netmonitor.sh -d 5 -i wlp2s0 -n 192.168.178.0/24
        Wartezeit von 5 Sekunden zwischen scanns, verwende interface wlp2s0 für Scanns, Suche im Netz 192.168.178.0 mit 
        einem Netzanteil von 24 Bit -> Subnetzmaske 255.255.255.0 

AUTHOR
    Adrian Jäger - jaegerad74878@th-nuernberg.de

HELPTEXT

    return
}

#Optionen Ermitteln
while [[ ${1::1} == '-' ]] ; do
    case $1 in
        --ping|-p)
            echo "Extra Pings ausgewählt"
            #Hänge alle Angegebnen Ziele an IP Liste an
            while [[ "${2::1}" != '-' ]] && [[ -n "${2::1}" ]] ; do
                shift
                IP_list=$( printf '%s%20s' "${IP_list}" "${1} ")
            done
            ;;

        --delay|-d)
            shift
            #Prüfe ob Verzögerung eine Ganzzahl ist
            if  [[ $1 =~ ^[0-9]+$ ]]; then
                echo "Verzögerung von $1 ausgwählt"
                intervall="$1"
            else
                echo "Invalides Intervall: $1"
                exit 1
            fi
            ;;

        --interface|-i)
            shift
            #Prüfe ob ein Interface angegeben
            if [[ $1 =~ ^[^-]+ ]]; then
                echo "Interface $1 ausgewählt"
                interface="--interface $1"
            else   
                echo "Invalides Interface: $1"
                exit 1
            fi
            ;;

        --network|-n)
            shift
            #Prüfe ob ein Netzwerk angegeben ist
            if [[ $1 =~ ^[^-]+ ]]; then
                echo "Netzwerk $1 ausgewählt"
                network="$1"
            else   
                echo "Invalides Netzwerk: $1"
                exit 1
            fi
            ;;

        --auswertung|-a)
            shift
            #Prüfe ob Datei vorhanden ist
            if [[ "${1::1}" != '-' ]] && [[ -n "${1::1}" ]] && test -f "$1"; then
                echo "Auswertungsmodus ausgewählt"
                filename="$1"
                scan_mode=0
            else
                echo "Invalide Datei: $1"
                exit 1
            fi
            ;;

        --help|-h)
            #Geben Manpage aus
            help
            exit 0
            ;;

        *)
            echo -e "Unbekannte Option: $1 \nHilfe mit netmonitor.sh -h"
            exit 1
            ;;
    esac
    shift

done

#Prüfe Abhängigkeiten, biete installation bei fehlen an
if [[ $scan_mode -eq "1" ]] && ! command -v arp-scan &> /dev/null
then
    read -p "arp-scan nicht gefunden, jetzt installieren? (j/n)" -n 1 -r
    if [[ $REPLY =~ ^[Jj]$ ]]
    then
        sudo apt-get install arp-scan
    else
        echo "Fehler: arp-scan nicht gefunden"
        exit 1
    fi
fi

if ! command -v gnuplot &> /dev/null
then
    read -p "gnuplot nicht gefunden, jetzt installieren? (j/n)" -n 1 -r
    if [[ $REPLY =~ ^[Jj]$ ]]
    then
        sudo apt-get install gnuplot
    else
        echo "Fehler: gnuplot nicht gefunden"
        exit 1
    fi
fi



#************************* NETWORK SCANNER PART *****************************************************

#Prüfe ob ein Netzwerkscann ausgeführt werden soll
if [[ scan_mode -eq "1" ]]; then

    #Konsolen Output
    echo -e "\nNetzwerkscanner gestartet \nWarnung: Admin Rechte zum generieren von ARP-Packages benötigt"

    #Generiere Dateinamen
    filename=$(date +"scan_%F.dat")

    #Outputfile Anlegen 
    first_line=$( printf '%-20s%s' "Zeit" "$IP_list " )
    echo "$first_line" >"$filename"        
        

    #Ermögliche STRG+C zum beenden der Schleife
    trap break INT

    #Zyklischer Aufruf
    while true ; do

        #Consol output
        echo -e "\nNächster Scann beginnt (STRG+C zum abbrechen): "

        #Get time for Output File
        OutputLine=$( printf '%-20s' "$(date +"%H:%M:%S") " )

        #Erkenne alle Geräte im Netzwerk mit arp-scan
        IP_arp=$(sudo arp-scan $network $interface --numeric --quiet --ignoredups --bandwidth 1000000 | 
            #Regex:         Valide IP-Adressse   spacing    MAC-Adresse
            grep -E '^([0-9]{1,3}\.){3}[0-9]{1,3}\s+([a-f0-9]{2}:){5}[a-f0-9]{2}' |
            #AWK: Gefundene Hostst als Liste ausgeben
            awk '{print $1}')
        #Alternative: nmap. Wesentlich mächtiger
        #IP_list=$(nmap -nsP 192.168.178.0/24 2>/dev/null -oG - | grep "Up$" | awk '{printf "%s ", $2}')


        #Prüfe ob Host bereits in Liste enthalten, wenn nicht füge hinten an
        for IP in $IP_arp
        do
            if [[ "$IP_list" != *"$IP"* ]]; then
                IP_list=$(printf '%s%20s' "${IP_list}" "${IP} ")
            fi
        done

        #Debug: Zeige liste
        #echo Hosts: "$IP_list"

        #Ping an Netzwerkteilnehmer
        for IP in $IP_list ;  do

            #Output for Console
            echo -n "Ping an ${IP}: "

            #Sende einen Ping
            ping_output=$(ping -q -n -w 1 -c 1 "${IP}")
            #debug echo
            #echo "${ping_output}"

            #Auswertung ob Ping erfolgreich war
            ping_ok=$(echo "${ping_output}" | grep "transmitted" | awk '{
                #printf("1: %s, 2: %s  \n\n", $1, $4)
                if ($1 == $4)
                    print "ok"
                else
                    print "error" }')

            #Zeige Ergebnis
            #echo -n "${ping_ok} "      

            #Zeige Ping Zeit wenn Ping erfolgreich war
            if [[ $ping_ok == "ok" ]] ; then
                ping_time=$(echo "${ping_output}" | grep "rtt" | perl -npe 's/.*=\s([0-9.]*)\/.*/$1\n/')
                echo "$ping_time" ms

                #Ausgabepuffer
                OutputLine=$(printf '%s%20s' "${OutputLine}" "${ping_time} ")
            else   
                echo "Error"

                #Ausgabepuffer
                OutputLine=$(printf '%s%20s' "${OutputLine}" "-100 ")
            fi


        done

        #Save scan to File
        echo "$OutputLine" >>"$filename"

        #Replace first Line to integrate new Hosts
        first_line=$( printf '%-20s%s' "Zeit" "$IP_list " )
        sed -i "1s/.*/$first_line/" "$filename"

        sleep "$intervall"

    done

    #Stop trap
    trap - INT

    echo -e "\nScan beendet\n"

fi



#********************** GNUPLOT PART ******************************************
#Initialisiere Variablen
HostList=
column_count=
plot_arg=
zeit_start=
zeit_end=
line_count=
word_count=

#Prüfe ob Logdatei genug Aufzeichnungen enthält
if [[ $(wc -l "$filename" | cut -d " " -f 1) -lt 3 ]]; then
    echo "Datei muss mindestens 2 Messwerte enthalten"
    exit 1
fi

#Start Konsolenoutput
echo -e "\n\nStarting to Plot File ${filename}:"

#Entnehme alle Hosts aus erster Zeile, trenne erste Spalte da dort "Zeit" steht
HostList="$(head -n 1 "$filename" | cut -d ' ' -f 2- | tr -s " ")"

#Debug, zeige Hostliste
echo "Hosts: $HostList"

#Setze Spaltenzähler auf 1 damit spalte 2 zuerst ausgelesen wird
column_count=1

#Baue Kommando für Gnuplot
plot_arg="plot "
for host in $HostList
do
    ((column_count++))
    plot_arg="${plot_arg} \"$filename\" using 1:$column_count title \"$host\" with linespoints,"
done
#Debug, zeige Kommando
#echo "$plot_arg"
#echo "Spaltenzahl: $column_count"

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
set ytics 0, 200, 1000
set xdata time
set timefmt "%H:%M:%S"
set format x "%H:%M:%S"
set xrange ["$zeit_start":"$zeit_end"]
set label "Timeout   " at "$zeit_start", -100 right
$plot_arg
PLOT

echo "Plot fertig"

exit 0
