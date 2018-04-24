#!/bin/bash
#tempmon.sh by Ca2F | www.findalen.no
#https://github.com/Ca2F/Grafana-homelab-scripts-for-ESXi-and-LSI-RAID-Controllers

#The main goal of this script is pulling temperature data from
#A LSI RAID controller installed on a vmware ESXi host.
#To utilize this script storcli has to be installed on the
#Vmware host first. Download it from the relevant LSI product page
#in my case here:
#https://www.broadcom.com/products/storage/raid-controllers/megaraid-sas-9271-8i#downloads
#Then under Management Sofware and Tools locate "Megaraid Storcli" for ALL OS
#Get the zip file and find the vmware folder, it should contain
#Several vmware folders, depending on your ESXi version:

#VMware KL (ESXi4.0, ESXi4.0 U1 and all other ESXi4.0 updates)
#VMware MN (ESXi5.0 and its updates, ESXi5.1 and its updates)
#VMware OP (ESXi5.5 and its updates, ESXi6.0 and its updates, and ESXi 6.5)

#Install the relevant .vib and edit this script to your needs
#It is setop for 8 disks defined with "temp1-temp8"
#To se if storcli works and what data you can collect
#run this in your ESXi shell: cd /opt/lsi/storcli && ./storcli /c0 show all
#c0 is for controller 0, if you have more then one the second one is /c1


#The time we are going to sleep between readings
sleeptime=60
#Prepare to start the loop and warn the user
echo "Press [CTRL+C] to stop..."
while :
do

temp1=$(sshpass -p "$YOUR_PASSWORD" ssh -t $esxiusername@10.0.0.2  "cd /opt/lsi/storcli && ./storcli /c0/e252/s0 show all | grep Temperature" | awk '{print $4}' | cut -c -2)
temp2=$(sshpass -p "$YOUR_PASSWORD" ssh -t $esxiusername@10.0.0.2  "cd /opt/lsi/storcli && ./storcli /c0/e252/s1 show all | grep Temperature" | awk '{print $4}' | cut -c -2)
temp3=$(sshpass -p "$YOUR_PASSWORD" ssh -t $esxiusername@10.0.0.2  "cd /opt/lsi/storcli && ./storcli /c0/e252/s2 show all | grep Temperature" | awk '{print $4}' | cut -c -2)
temp4=$(sshpass -p "$YOUR_PASSWORD" ssh -t $esxiusername@10.0.0.2  "cd /opt/lsi/storcli && ./storcli /c0/e252/s3 show all | grep Temperature" | awk '{print $4}' | cut -c -2)
temp5=$(sshpass -p "$YOUR_PASSWORD" ssh -t $esxiusername@10.0.0.2  "cd /opt/lsi/storcli && ./storcli /c0/e252/s4 show all | grep Temperature" | awk '{print $4}' | cut -c -2)
temp6=$(sshpass -p "$YOUR_PASSWORD" ssh -t $esxiusername@10.0.0.2  "cd /opt/lsi/storcli && ./storcli /c0/e252/s5 show all | grep Temperature" | awk '{print $4}' | cut -c -2)
temp7=$(sshpass -p "$YOUR_PASSWORD" ssh -t $esxiusername@10.0.0.2  "cd /opt/lsi/storcli && ./storcli /c0/e252/s6 show all | grep Temperature" | awk '{print $4}' | cut -c -2)
temp8=$(sshpass -p "$YOUR_PASSWORD" ssh -t $esxiusername@10.0.0.2  "cd /opt/lsi/storcli && ./storcli /c0/e252/s7 show all | grep Temperature" | awk '{print $4}' | cut -c -2)
raidtemp=$(sshpass -p "$YOUR_PASSWORD" ssh -t $esxiusername@10.0.0.2  "cd /opt/lsi/storcli && ./storcli /c0 show all | grep ROC" | awk 'NR==2' | awk '{print $5}'| cut -c -2)

echo $temp1

    #write the data to the database
curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "storage_data,host=LSI-RAID5,diskname=Disk_1 disktemperature=$temp1"
curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "storage_data,host=LSI-RAID5,diskname=Disk_2 disktemperature=$temp2"
curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "storage_data,host=LSI-RAID5,diskname=Disk_3 disktemperature=$temp3"
curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "storage_data,host=LSI-RAID5,diskname=Disk_4 disktemperature=$temp4"
curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "storage_data,host=LSI-RAID5,diskname=Disk_5 disktemperature=$temp5"
curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "storage_data,host=LSI-RAID5,diskname=Disk_6 disktemperature=$temp6"
curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "storage_data,host=LSI-RAID5,diskname=Disk_7 disktemperature=$temp7"
curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "storage_data,host=LSI-RAID5,diskname=Disk_8 disktemperature=$temp8"
curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "health_data,host=denhost1,sensor=raidtemp value=$raidtemp"

    #Wait for a bit before checking again
    sleep "$sleeptime"
done
