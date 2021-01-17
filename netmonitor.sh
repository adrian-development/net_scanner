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
IP_list=
OutputLine=
scan_mode=1
intervall=10

#Help Funktion
function help ()
{
    cat <<HELPTEXT
NAME
    netmonitor.sh
    Nimmt eine Analyse Ihres Netzwerks vor.
SYNOPSIS
    netmonitor.sh [-p|--ping hosts] [-h|--help] [-i|--intervall wartezeit] [-a|--auswertung filename]
DESCRIPTION
    Netmonitor ermittelt über einen ARP-Scan zyklisch sämtliche Geräte in Ihrem IPv4 Netzwerkes und pingt dieses an
    um die performance über längere Zeitabschnitte zu protokollieren. Die Messdaten werden in einer separaten Datei
    gespeichert und nach Ende des Scans graphisch dargestellt.
    Die Messung wird durch STRG+C gestoppt
EXAMPLES
    netmonitor.sh: Startet die Aufzeichung im Standardintervall von 10 Sekunden
    netmonitor.sh --ping www.google.de 141.75.201.12 --intervall 20: Pingt zusätzliche die google und die genannte IP
    alle 20 Sekunden an.
    netmonitor.sh --auswertung scan_2021-01-17: Startet keinen Scan sondern wertet eine bereits erstellt Datei aus
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
                IP_list=$( printf '%s%20s' "${IP_list}" "${1}")
            done
            ;;

        --interval|-i)
            shift
            #Prüfe ob Intervall eine Ganzzahl ist
            if  [[ $1 =~ ^[0-9]+$ ]]; then
                echo "Intervall von $1 ausgwählt"
                intervall="$1"
            else
                echo "Invalides Intervall: $1"
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

        --hepl|-h)
            #Geben Manpage aus
            help
            exit 0
            ;;

        *)
            echo "Unbekannte Option: $1"
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

#Prüfe ob ein Netzwerkscann ausgeführt werden soll
if [[ scan_mode -eq "1" ]]; then

    #Consolen Output
    echo -e "Netzwerkscanner gestartet \nWarnung: Admin Rechte zum generieren von ARP-Packages benötigt\n"

    #Generiere Dateinamen
    filename=$(date +"scan_%F")

    #Outputfile Anlegen 
    echo Zeit "${IP_list}" >"$filename"

    #Ermögliche STRG+C zum beenden der Schleife
    trap break INT

    #Zyklischer Aufruf
    while true ; do

        #Consol output
        echo -n "Nächster Scann beginnt: "

        #Get time for Output File
        OutputLine=$( printf '%-20s' "$(date +"%H:%M:%S")" )

        #Erkenne alle Geräte im Netzwerk mit arp-scan
        IP_arp=$(sudo arp-scan --localnet --numeric --quiet --ignoredups --bandwidth 1000000 | grep -E '([a-f0-9]{2}:){5}[a-f0-9]{2}' | awk '{print $1}')
        #Alternative: nmap. Wesentlich mächtiger
        #IP_list=$(nmap -nsP 192.168.178.0/24 2>/dev/null -oG - | grep "Up$" | awk '{printf "%s ", $2}')


        #Prüfe ob Host bereits in Liste enthalten, wenn nicht füge hinten an
        for IP in $IP_arp
        do
            if [[ "$IP_list" != *"$IP"* ]]; then
                IP_list=$(printf '%s%20s' "${IP_list}" "${IP}")
            fi
        done

        #Debug: Zeige liste
        echo Hosts: "$IP_list"

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
                OutputLine=$(printf '%s%20s' "${OutputLine}" "${ping_time}")
            else   
                echo "Error"

                #Ausgabepuffer
                OutputLine=$(printf '%s%20s' "${OutputLine}" "-100")
            fi


        done

        #Save scan to File
        echo "$OutputLine" >>"$filename"

        #Replace first Line to integrate new Hosts
        first_line=$( printf '%-20s%s' "Zeit" "$IP_list" )
        sed -i "1s/.*/$first_line/" "$filename"

        sleep "$intervall"

    done

    #Stop trap
    trap - INT

fi


#Starte Auswertung
./plotit.sh "$filename"

echo Fertig

exit 0