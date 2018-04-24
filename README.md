# Grafana-homelab-scripts-for-ESXi-and-LSI-RAID-Controllers
A set of scripts customized for displaying relevant home lab metrics from ESXi and a attached LSI RAID controller.

![Grafana Dashboard](https://github.com/Ca2F/Grafana-homelab-scripts-for-ESXi-and-LSI-RAID-Controllers/blob/master/grafana-github.png?raw=true)

I set out to create an awesome Grafana Dashboard for my home lab a couple of weeks ago. 
It is now in a presentable state, but i will update this further when i find the time.

My main home server consists of a Supermicro motherboard with the intel 2680v1 CPU.
I use Vmware ESXi and Pfsense for my router, and a LSI 9271i-8i RAID controller. 
If you ever have tried to get useful information from a LSI controller installed on a ESXi host you
would know it's not that easy. When i set out on this project i had no idea how hard it would be.

If you've ever used the MegaRAID storage java utility you know it's slow, prone to crashing and hard to setup.
My biggest problem with it is that i can't look up information easy on it. 
This should have been easily resolved in ESXi vSphere, but the only information you get there looks something like this:

![esxi storage](https://github.com/Ca2F/Grafana-homelab-scripts-for-ESXi-and-LSI-RAID-Controllers/blob/master/esxi-storage.png?raw=true)

Not much information there, but it could be useful and i know you can pull the information with SNMP if you want. 
But that is not the data i want, i want the induvidual disk temperatures since my server is in a tower case and i want to monitor every temperature i can get. I want CPU temps, system temps, disk temps, RAID chip temps etc.
The ESXi temperature section provides only this:

![esxi temps](https://github.com/Ca2F/Grafana-homelab-scripts-for-ESXi-and-LSI-RAID-Controllers/blob/master/esxi-temp.png?raw=true)


This whole setup is installed on a VM, running Docker with Grafana and InfluxDB as Docker containers.
How to set it up is not part of this readme, but plenty of guides out there both for Docker and regular install's.

All the scripts should be semi readable and easy to adjust to your enviroment, this git is a friendly share more then a serious project. 
However i really hope someone can benefit from it, especially for those of you wanting to read disk temperatures for a LSI RAID-controller installed on a ESXi host. It might be a special usecase, but should not be unique to only me i hope.

SETUP:

Every scripts has a small readme inside, but i'll put the dependencies here:

apt-get install sshpass
apt-get install ipmi-tool
apt-get install net-snmp
git clone https://github.com/Napsty/check_esxi_hardware

And most importantly storcli for the ESXi host:

https://www.broadcom.com/products/storage/raid-controllers/megaraid-sas-9271-8i#downloads
Then under Management Sofware and Tools locate "Megaraid Storcli" for ALL OS
Get the zip file and find the vmware folder, it should contain
Several vmware folders, depending on your ESXi version:

VMware KL (ESXi4.0, ESXi4.0 U1 and all other ESXi4.0 updates)
VMware MN (ESXi5.0 and its updates, ESXi5.1 and its updates)
VMware OP (ESXi5.5 and its updates, ESXi6.0 and its updates, and ESXi 6.5)




