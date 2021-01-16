#!/bin/bash

echo -e "Netzwerkscanner gestartet \nWarnung admin rechte zum generieren von ARP-Packages benötigt\n"

#Konstanten
OUTPUT_FILE="./scan.dat"

#Variablen initialisieren
IP_list=
OutputLine=


#Optionen Ermitteln
while [[ ${1::1} == '-' ]] ; do
    case $1 in
        --ping|-p)
            echo "Extra Pings ausgewählt"
            shift
            while [ "${1::1}" != '-' -a -n "${1::1}" ] ; do
                IP_list=$( printf '%s%20s' "${IP_list}" "${1}")
                shift
            done
            ;;

        *)
            echo "Unbekannte Option" $1
            ;;
    esac
    shift

done

#Prüfe Vorausetzungen
if ! command -v arp-scan &> /dev/null
then
    read -p "arp-scan could not be found, install now? (y/n)" -n 1 -r
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        sudo apt-get install arp-scan
    fi
fi

if ! command -v gnuplot &> /dev/null
then
    read -p "gnuplot could not be found, install now? (y/n)" -n 1 -r
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        sudo apt-get install gnuplot
    fi
fi

#Zum Testen: Einmale Host-String anlegen und deise zyklisch anpingen
#IP_arp=$(sudo arp-scan --localnet --numeric --quiet --ignoredups --bandwidth 1000000 | grep -E '([a-f0-9]{2}:){5}[a-f0-9]{2}' | awk '{print $1}')
#IP_list="${IP_list} ${IP_arp}"
#echo Ping geht an $IP_list

#Outputfile Anlegen 
echo Zeit ${IP_list} >$OUTPUT_FILE

#Zyklischer Aufruf
while true ; do

    #Consol output
    echo Next Scan:

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
            echo $ping_time ms

            #Ausgabepuffer
            OutputLine=$(printf '%s%20s' "${OutputLine}" "${ping_time}")
        else   
            echo "Error"

            #Ausgabepuffer
            OutputLine=$(printf '%s%20s' "${OutputLine}" "-100")
        fi


    done

    #Save scan to File
    echo "$OutputLine" >>$OUTPUT_FILE

    #Replace first Line to integrate new Hosts
    first_line=$( printf '%-20s%s' "Zeit" "$IP_list" )
    sed -i "1s/.*/$first_line/" $OUTPUT_FILE

    sleep 1

done


echo ende

exit 0