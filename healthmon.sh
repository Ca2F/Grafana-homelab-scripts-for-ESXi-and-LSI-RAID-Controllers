#!/bin/bash
#healthmon.sh by Ca2F | www.findalen.no
#https://github.com/Ca2F/Grafana-homelab-scripts-for-ESXi-and-LSI-RAID-Controllers

#This script pulls IPMI data from my supermicro motherboard
#in order to show temperatures and fan speed.
#It should work on all supermicro motherboards with a built-in
#IPMI controller or add-on card.
#It's configured to pull temps from CPU1, systemtemp, peripheraltemp
#And fan speeds from FAN1-FAN6 and FAN-A that is the CPU FAN1

#The time we are going to sleep between readings

sleeptime=30

#Command we will be using is ipmi tool - sudo apt-get install ipmitool
#Default user/pass is ADMIN ADMIN as configured in this script

#Sample Data
#CPU1 Temp        | 41 degrees C      | ok
#CPU2 Temp        | no reading        | ns
#System Temp      | 38 degrees C      | ok
#Peripheral Temp  | 40 degrees C      | ok
#PCH Temp         | 53 degrees C      | ok
#P1-DIMMC1 TEMP   | 80 degrees C      | nc
#P1-DIMMC2 TEMP   | no reading        | ns
#P1-DIMMC3 TEMP   | no reading        | ns
#P1-DIMMD1 TEMP   | 80 degrees C      | nc
#P1-DIMMD2 TEMP   | no reading        | ns
#P1-DIMMD3 TEMP   | no reading        | ns
#P2-DIMME1 TEMP   | no reading        | ns
#FAN1             | 1200 RPM          | ok
#FAN2             | 1950 RPM          | ok
#FAN3             | 1950 RPM          | ok
#FAN4             | 1050 RPM          | ok
#FAN5             | 1275 RPM          | ok
#FAN6             | 4875 RPM          | ok
#FANA             | 675 RPM           | ok
#FANB             | no reading        | ns
#VTT              | 1.06 Volts        | ok
#CPU1 Vcore       | 1.06 Volts        | ok
#CPU2 Vcore       | no reading        | ns
#VDIMM AB         | 1.47 Volts        | ok
#VDIMM CD         | 1.49 Volts        | ok
#VDIMM EF         | no reading        | ns
#VDIMM GH         | no reading        | ns
#+1.1 V           | 1.10 Volts        | ok
#+1.5 V           | 1.49 Volts        | ok
#3.3V             | 3.26 Volts        | ok
#+3.3VSB          | 3.36 Volts        | ok
#5V               | 4.99 Volts        | ok
#+5VSB            | 4.99 Volts        | ok
#12V              | 12.19 Volts       | ok
#VBAT             | 3.12 Volts        | ok
#HDD Status       | no reading        | ns
#Chassis Intru    | 0x00              | ok

get_ipmi_data () {
    COUNTER=0
    while [  $COUNTER -lt 4 ]; do
        #Get ipmi data
        ipmitool -H 10.0.0.90 -U ADMIN -P ADMIN sdr > tempdatafile
        cputemp=`cat tempdatafile | grep "CPU1 Temp" | cut -f2 -d"|" | grep -o '[0-9]\+'`
        systemtemp=`cat tempdatafile | grep "System Temp" | cut -f2 -d"|" | grep -o '[0-9]\+'`
        periphtemp=`cat tempdatafile | grep "Peripheral Temp" | cut -f2 -d"|" | grep -o '[0-9]\+'`
        pchtemp=`cat tempdatafile | grep "PCH Temp" | cut -f2 -d"|" | grep -o '[0-9]\+'`
	      fan1=`cat tempdatafile | grep "FAN1" | cut -f2 -d"|" | grep -o '[0-9]\+'`
	      fan2=`cat tempdatafile | grep "FAN2" | cut -f2 -d"|" | grep -o '[0-9]\+'`
        fan3=`cat tempdatafile | grep "FAN3" | cut -f2 -d"|" | grep -o '[0-9]\+'`
        fan4=`cat tempdatafile | grep "FAN4" | cut -f2 -d"|" | grep -o '[0-9]\+'`
        fan5=`cat tempdatafile | grep "FAN5" | cut -f2 -d"|" | grep -o '[0-9]\+'`
        fan6=`cat tempdatafile | grep "FAN6" | cut -f2 -d"|" | grep -o '[0-9]\+'`
        fanA=`cat tempdatafile | grep "FANA" | cut -f2 -d"|" | grep -o '[0-9]\+'`

        rm tempdatafile

        if [[ $cputemp -le 0 || $systemtemp -le 0 || $periphtemp -le 0 || $pchtemp -le 0 || $fan1 -le 0 || $fan2 -le 0 || $fan3 -le 0 || $fan4 -le 0 || $fan5 -le 0 || $fan6 -le 0 || $fanA -le 0 ]];
        	then
                echo "Retry getting data - received some invalid data from the read"
            else
                #We got good data - exit this loop
                COUNTER=10
        fi
        let COUNTER=COUNTER+1
    done
}

print_data () {
    echo "CPU Temperature: $cputemp"
    echo "System Temperature: $systemtemp"
    echo "Peripheral Temperature: $periphtemp"
    echo "PCH Temperature: $pchtemp"
    echo "Fan1 Speed: $fan1"
    echo "Fan2 Speed: $fan2"
    echo "Fan3 Speed: $fan3"
    echo "Fan4 Speed: $fan4"
    echo "Fan5 Speed: $fan5"
    echo "Fan6 Speed: $fan6"
    echo "FanA Speed: $fanA"

}

write_data () {
    #Write the data to the database
    curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "health_data,host=esxi,sensor=cputemp value=$cputemp"
    curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "health_data,host=esxi,sensor=systemtemp value=$systemtemp"
    curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "health_data,host=esxi,sensor=periphtemp value=$periphtemp"
    curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "health_data,host=esxi,sensor=pchtemp value=$pchtemp"
    curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "health_data,host=esxi,sensor=fan1 value=$fan1"
    curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "health_data,host=esxi,sensor=fan2 value=$fan2"
    curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "health_data,host=esxi,sensor=fan3 value=$fan3"
    curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "health_data,host=esxi,sensor=fan4 value=$fan4"
    curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "health_data,host=esxi,sensor=fan5 value=$fan5"
    curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "health_data,host=esxi,sensor=fan6 value=$fan6"
    curl -i -XPOST 'http://localhost:8086/write?db=home' --data-binary "health_data,host=esxi,sensor=fanA value=$fanA"

}

#Prepare to start the loop and warn the user
echo "Press [CTRL+C] to stop..."
while :
do
    #Sleep between readings
    sleep "$sleeptime"

    get_ipmi_data

    if [[ $cputemp -le 0 || $systemtemp -le 0 || $periphtemp -le 0 || $pchtemp -le 0 || $fan1 -le 0 || $fan2 -le 0 || $fan3 -le 0 || $fan4 -le 0 || $fan5 -le 0|| $fan6 -le 0 || $fanA -le 0 ]];
    	then
            echo "Skip this datapoint - something went wrong with the read"
        else
            #Output console data for future reference
            print_data
            write_data
    fi
done
