#!/bin/bash
#diskspace.sh by Ca2F | www.findalen.no
#https://github.com/Ca2F/Grafana-homelab-scripts-for-ESXi-and-LSI-RAID-Controllers

#This script gets used diskspace from my various .vmdk virtual disks
#I sshpass into a vm that uses all these .vmdk's and pushes
#the used space in bits to influxDB
#In grafana i use math(*1024) and the unit bytes for a
#nice singlestat telling me if im running out of diskspace
#and need to expand my virtualdisks or do some cleaning.

##Configure:
#Replace $YOUR_PASSWORD with the ssh password and $USER with
# ssh username@ip for the machine you want to read diskspace from.

# I made a crontab to run this script every 5min
# */5 * * * * /home/$USER/diskspace.sh

serier=$(sshpass -p "$YOUR_PASSWORD" ssh -t $USER@10.10.0.100 "df" | grep /media/serier | awk '{print $3}')
hd=$(sshpass -p "$YOUR_PASSWORD" ssh -t $USER@10.10.0.100 "df" | grep /media/hd | awk '{print $3}')
downloads=$(sshpass -p "$YOUR_PASSWORD" ssh -t $USER@10.10.0.100 "df" | grep /media/downloads | awk '{print $3}')
random=$(sshpass -p "$YOUR_PASSWORD" ssh -t $USER@10.10.0.100 "df" | grep /media/random | awk '{print $3}')
seed=$(sshpass -p "$YOUR_PASSWORD" ssh -t $USER@10.10.0.100 "df" | grep /media/seed | awk '{print $3}')

total=$(($serier+$hd+$downloads+$random+$seed))

echo $total

#Writing data to database
curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "storage_data,host=storage,diskname=serier diskspace=$serier"
curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "storage_data,host=storage,diskname=hd diskspace=$hd"
curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "storage_data,host=storage,diskname=downloads diskspace=$downloads"
curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "storage_data,host=storage,diskname=random diskspace=$random"
curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "storage_data,host=storage,diskname=total diskspace=$total"

# A total of all disks if needed
curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "storage_data,host=storage,diskname=raidspace diskspace=23000"
