#!/bin/bash

echo "Netzwerkscanner gestartet"

#Konstanten
OUTPUT_FILE="./scan.dat"

#Variablen initialisieren
IPs=
OutputLine=


#Optionen Ermitteln
while [[ ${1::1} == '-' ]] ; do
    case $1 in
        --ping|-p)
            echo "Extra Pings ausgewählt"
            shift
            while [ "${1::1}" != '-' -a -n "${1::1}" ] ; do
                IPs="${IPs} ${1}"
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
    echo "arp-scan could not be found, install now? (y/n)"
    read -p "Are you sure? " -n 1 -r
    echo    # (optional) move to a new line
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        sudo apt-get install arp-scan
    fi

        
fi

#Zum Testen: Einmale Host-String anlegen und deise zyklisch anpingen
IP_arp=$(sudo arp-scan --localnet --numeric --quiet --ignoredups --bandwidth 1000000 | grep -E '([a-f0-9]{2}:){5}[a-f0-9]{2}' | awk '{print $1}')
IPs="${IPs} ${IP_arp}"
echo Ping geht an $IPs

echo Zeit ${IPs} >$OUTPUT_FILE

#Zyklischer Aufruf
while true ; do

    #Get time for Output File
    OutputLine=$(date +"%H.%M%S")

    #Erkenne alle Geräte im Netzwerk mit arp-scan
    IP_arp=$(sudo arp-scan --localnet --numeric --quiet --ignoredups --bandwidth 1000000 | grep -E '([a-f0-9]{2}:){5}[a-f0-9]{2}' | awk '{print $1}')
    for IP in $IP_arp
    do
        if [[ "$IP" != *"$SUB"* ]]; then
            IPs="${IPs} ${IP}"
        fi
    done

    #Alternative: nmap. Wesentlich mächtiger
    #IPs=$(nmap -nsP 192.168.178.0/24 2>/dev/null -oG - | grep "Up$" | awk '{printf "%s ", $2}')

    #Ping an Netzwerkteilnehmer
    for IP in $IPs ;  do
        #Output for Console
        echo -n "Ping an ${IP}: "

        #Sende einen Ping
        ping_output=$(ping -q -n -w 1 -c 3 "${IP}")
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
            OutputLine="${OutputLine} ${ping_time}"
        else   
            echo "Error"

            #Ausgabepuffer
            OutputLine="${OutputLine} -10"
        fi


    done

    #Save scan to File
    echo $OutputLine >>$OUTPUT_FILE

    sleep 2

done


echo ende

exit 0