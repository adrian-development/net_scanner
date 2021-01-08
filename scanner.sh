#!/bin/bash

echo "Netzwerkscanner gestartet"

#Variablen initialisieren
ping_flag= 
ping_adress_arr=
ping_adress_count=0

#Optionen Ermitteln
while [[ ${1::1} == '-' ]] ; do
    case $1 in
        --ping|-p)
            ping_flag = 1
            shift
            ping_adress[ping_adress_count]=$1
            ((ping_adress_count++))
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
    echo "arp-scan could not be found"
    exit
fi


#Zyklischer Aufruf
while true ; do

    #Erkenne alle Geräte im Netzwerk
    IPs=$(sudo arp-scan --localnet --numeric --quiet --ignoredups | grep -E '([a-f0-9]{2}:){5}[a-f0-9]{2}' | awk '{print $1}')

    echo "${IPs}"

    sleep 5

done


echo ende

exit 0