#!/bin/bash

echo "Netzwerkscanner gestartet"

#Variablen initialisieren
ping_adress_arr=
ping_adress_count=0

#Optionen Ermitteln
while [[ ${1::1} == '-' ]] ; do
    case $1 in
        --ping|-p)
            echo "Extra Pings ausgewählt"
            shift
            while [ "${1::1}" != '-' -a -n "${1::1}" ] ; do
                ping_adress_arr[${ping_adress_count}]=$1
                (( ping_adress_count++ ))
                shift
            done
            ;;

        *)
            echo "Unbekannte Option" $1
            ;;
    esac
    shift

done

echo ${ping_adress_arr[0]}

#Prüfe Vorausetzungen

if ! command -v arp-scan &> /dev/null
then
    echo "arp-scan could not be found"
    exit
fi


#Zyklischer Aufruf
while true ; do

    #Erkenne alle Geräte im Netzwerk
    IPs=$(sudo arp-scan --localnet --numeric --quiet --ignoredups --bandwidth 1000000 | grep -E '([a-f0-9]{2}:){5}[a-f0-9]{2}' | awk '{print $1}')

    echo "${IPs}"

    ping $IPs

    #Zusätzliche pings
    for item in ${ping_adress_arr[*]}
    do
        echo ping geht los
        ping -q -n -c 1 "${item}"
    done

    sleep 5

done


echo ende

exit 0