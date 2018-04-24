#!/bin/bash
#raidplex.sh by Ca2F | www.findalen.no
#https://github.com/Ca2F/Grafana-homelab-scripts-for-ESXi-and-LSI-RAID-Controllers

#This script gets the current RAID State. Optimal and DEGRADED
#And polls your plex server for current transcodes
#For this script to be fully functional storcli needs to be
#installed on the ESXi host in as described in the tempmon.sh script
#and check_esxi_hardware.py has to be in the same folder as this!

#You can find it on github here:
#https://github.com/Napsty/check_esxi_hardware

# To have this run at boot time i made a crontab
# @reboot /home/cato/raidplex.sh

#The time we are going to sleep between readings
sleeptime=60

#Prepare to start the loop and warn the user
echo "Press [CTRL+C] to stop..."
while :
do

    #Let's start with the "easy" one, get the number of transcodes
    numtranscodes=$(sh ~/plexinfo.sh)
    echo "Plex transcodes $numtranscodes"
    #then pull the RAID STATUS from the LSI controller through storcli on the esxi host

RAID1=$(./check_esxi_hardware.py -H 10.0.0.2 -U root -P $YOUR_PASSWORD -v | grep "500605b00080cf60_0" | awk 'NR==1' | awk '{print $17}')
RAID5=$(./check_esxi_hardware.py -H 10.0.0.2 -U root -P $YOUR_PASSWORD -v | grep "5000000012345678_0" | awk 'NR==1' | awk '{print $17}')


    #Write the data to the database
    curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "plex_info,host=denhost1 transcodes=$numtranscodes"
    curl -i -X POST 'http://localhost:8086/write?db=home' --data-binary 'health_data,host=RAID,card=RAID1 status="'"$RAID1"'"'
    curl -i -X POST 'http://localhost:8086/write?db=home' --data-binary 'health_data,host=RAID,card=RAID5 status="'"$RAID5"'"'
    #Wait for a bit before checking again
    sleep "$sleeptime"
done
