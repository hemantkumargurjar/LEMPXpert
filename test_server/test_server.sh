#!/bin/bash

# ASCII art logo using figlet
logo_text=$(figlet "LEMPXpert")


display_menu() {
    echo "$logo_text"
}

# Remove temporary directory if it exists
[ -d /tmp/server_info ] && rm -rf /tmp/server_info

# Create a temporary directory to store server info
mkdir -p /tmp/server_info

# Fetch server information
curl -sS ipinfo.io > /tmp/server_info/ipinfo.txt
svip=$(wget http://ipecho.net/plain -O - -q ; echo)

# Clean up and format the fetched data
sed -i 's/,//g' /tmp/server_info/ipinfo.txt
sed -i 's/"//g' /tmp/server_info/ipinfo.txt

# Clear the terminal
clear

echo "========================================================================="
echo "Server Information and Speed Test"
echo "========================================================================="

# Display IP's Info
echo "IP's Info:"
echo "-------------------------------------------------------------------------"
echo "Host name: $(awk 'NR==3' /tmp/server_info/ipinfo.txt)"
echo "City: $(awk 'NR==4' /tmp/server_info/ipinfo.txt)"
echo "Region: $(awk 'NR==5' /tmp/server_info/ipinfo.txt)"
echo "Country: $(awk 'NR==6' /tmp/server_info/ipinfo.txt)"
echo "Latitude/Longitude: $(awk 'NR==7' /tmp/server_info/ipinfo.txt)"

# Display Server Info
echo "========================================================================="
echo "Server Info:"
echo "-------------------------------------------------------------------------"
cname=$(awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo)
cores=$(awk -F: '/model name/ {core++} END {print core}' /proc/cpuinfo)
freq=$(awk -F: ' /cpu MHz/ {freq=$2} END {print freq}' /proc/cpuinfo)
tram=$(free -m | awk 'NR==2 {print $2}')
swap=$(free -m | grep ^Swap | tr -s ' ' | cut -d ' ' -f 2)
up=$(uptime | awk '{print $3,$4}' | sed 's/,//')

echo "Server's IP: $svip"
echo "Server Type: $(virt-what | awk 'NR==1 {print $NF}')"
echo "CPU Model: $cname"
echo "Number of Cores: $cores"
echo "CPU Frequency: $freq MHz"
echo "RAM: $tram MB"
echo "Swap: $swap MB"
echo "System Uptime: $up"

# Display Disk Info
echo "========================================================================="
echo "Disk Info:"
echo "-------------------------------------------------------------------------"
svhdd=$(df -h | awk 'NR==2 {print $2}')
tocdohdd=$(dd if=/dev/zero of=/tmp/testfile bs=64k count=16k conv=fdatasync 2>&1 | tail -1 | awk '{print $NF}')

echo "Total Disk: $svhdd"
echo "Disk Free: $(df -h $PWD | awk '/[0-9]%/{print $4}')"
echo "Disk Speed: $tocdohdd"

# Display SpeedTest Info
echo "========================================================================="
echo "SpeedTest:"
echo "-------------------------------------------------------------------------"

speed_test() {
    url="$1"
    location="$2"
    speed=$(wget -O /dev/null "$url" 2>&1 | awk '/\/dev\/null/ {gsub(/\(|\)/,"",$3); print $3}')
    echo "Download speed from $location: $speed"
}

speed_test "http://cachefly.cachefly.net/100mb.test" "CacheFly"
speed_test "http://speed.atl.coloat.com/100mb.test" "Coloat, Atlanta GA"
speed_test "http://speedtest.dal05.softlayer.com/downloads/test100.zip" "Softlayer, Dallas, TX"
speed_test "http://speedtest.tokyo.linode.com/100MB-tokyo.bin" "Linode, Tokyo, JP"
speed_test "http://mirror.i3d.net/100mb.bin" "i3d.net, Rotterdam, NL"
speed_test "http://mirror.leaseweb.com/speedtest/100mb.bin" "Leaseweb, Haarlem, NL"
speed_test "http://speedtest.sng01.softlayer.com/downloads/test100.zip" "Softlayer, Singapore"
speed_test "http://speedtest.sea01.softlayer.com/downloads/test100.zip" "Softlayer, Seattle, WA"
speed_test "http://speedtest.sjc01.softlayer.com/downloads/test100.zip" "Softlayer, San Jose, CA"
speed_test "http://speedtest.wdc01.softlayer.com/downloads/test100.zip" "Softlayer, Washington, DC"


echo "========================================================================="
echo "Checking Finished."
echo "========================================================================="
exit
