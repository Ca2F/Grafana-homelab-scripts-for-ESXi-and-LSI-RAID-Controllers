#!/bin/bash
#inetmon.sh by Ca2F | www.findalen.no
#https://github.com/Ca2F/Grafana-homelab-scripts-for-ESXi-and-LSI-RAID-Controllers

#This script uses snmp to pull current bandwidth usage from my
#pfsense router hosted inside Vmware ESXi.
#It pulls both in and out data for two interfaces.
#And pushes it into influxDB, in grafana use math(*8) and
#use bits/sec as the unit type.
#These oid/mib's works on pfsense, but on different routers
#Your milage may vary, however the IF-MIB::ifInOctets should
#be pretty standard. Do a mibwalk if you are trying this on a
#different setup!

#The time we are going to sleep between readings
#A value between 10 and 30 seconds i found optimal
#you will never loose data by setting this to a larger value.
sleeptime=10

#We need to get a baseline for the traffic before starting the loop
#otherwise we have nothing to base out calculations on.

#Get in and out octets
oldin=`snmpget -v 2c -c public 10.0.0.1 IF-MIB::ifInOctets.2 -Ov`
oldout=`snmpget -v 2c -c public 10.0.0.1 IF-MIB::ifOutOctets.2 -Ov`
lanoldin=`snmpget -v 2c -c public 10.0.0.1 IF-MIB::ifInOctets.1 -Ov`
lanoldout=`snmpget -v 2c -c public 10.0.0.1 IF-MIB::ifOutOctets.1 -Ov`

#Strip out the value from the string
oldin=$(echo $oldin | cut -c 12-)
oldout=$(echo $oldout | cut -c 12-)
lanoldin=$(echo $lanoldin | cut -c 12-)
lanoldout=$(echo $lanoldout | cut -c 12-)

#Prepare to start the loop and warn the user
echo "Press [CTRL+C] to stop..."
while :
do
    #We need to wait between readings to have somthing to compare to
    sleep "$sleeptime"

    #Get in and out octets
    in=`snmpget -v 2c -c public 10.0.0.1 IF-MIB::ifInOctets.2 -Ov`
    out=`snmpget -v 2c -c public 10.0.0.1 IF-MIB::ifOutOctets.2 -Ov`
    lanin=`snmpget -v 2c -c public 10.0.0.1 IF-MIB::ifInOctets.1 -Ov`
    lanout=`snmpget -v 2c -c public 10.0.0.1 IF-MIB::ifOutOctets.1 -Ov`

    #Strip out the value from the string
    in=$(echo $in | cut -c 12-)
    out=$(echo $out | cut -c 12-)
    lanin=$(echo $lanin | cut -c 12-)
    lanout=$(echo $lanout | cut -c 12-)

    #Get the difference between the old and current
    diffin=$((in - oldin))
    diffout=$((out - oldout))
    landiffin=$((lanin - lanoldin))
    landiffout=$((lanout - lanoldout))

    #Calculate the bytes-per-second
    inbps=$((diffin / sleeptime))
    outbps=$((diffout / sleeptime))
    laninbps=$((landiffin / sleeptime))
    lanoutbps=$((landiffout / sleeptime))

    #Seems we need some basic data validation - can't have values less than 0!
    if [[ $inbps -lt 0 || $outbps -lt 0 || $laninbps -lt 0 || $lanoutbps -lt 0 ]];
    then
        #There is an issue with one or more readings, get fresh ones
        #then wait for the next loop to calculate again.
        echo "We have a problem...moving to plan B"

        #Get in and out octets
        oldin=`snmpget -v 2c -c public 10.0.0.1 IF-MIB::ifInOctets.2 -Ov`
        oldout=`snmpget -v 2c -c public 10.0.0.1 IF-MIB::ifOutOctets.2 -Ov`
        lanoldin=`snmpget -v 2c -c public 10.0.0.1 IF-MIB::ifInOctets.1 -Ov`
        lanoldout=`snmpget -v 2c -c public 10.0.0.1 IF-MIB::ifOutOctets.1 -Ov`

        #Strip out the value from the string
        oldin=$(echo $oldin | cut -c 12-)
        oldout=$(echo $oldout | cut -c 12-)
        lanoldin=$(echo $lanoldin | cut -c 12-)
        lanoldout=$(echo $lanoldout | cut -c 12-)
    else
        #Output the current traffic
        echo "Main current inbound traffic: $inbps bps"
        echo "Main current outbound traffic: $outbps bps"
        echo "lan/Guest current inbound traffic: $laninbps bps"
        echo "lan/Guest current outbound traffic: $lanoutbps bps"

        #Write the data to the database
        curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "network_traffic,host=pfsense,interface=eth1wan,direction=inbound value=$inbps"
        curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "network_traffic,host=pfsense,interface=eth1wan,direction=outbound value=$outbps"
        curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "network_traffic,host=pfsense,interface=eth2lan,direction=outbound value=$laninbps"
        curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "network_traffic,host=pfsense,interface=eth2lan,direction=inbound value=$lanoutbps"

        #Move the current variables to the old ones
        oldin=$in
        oldout=$out
        lanoldin=$lanin
        lanoldout=$lanout
    fi

done
