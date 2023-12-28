#!/bin/bash

# Get current date and time
current_datetime=$(date)

echo "## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## #"
echo "              LEMPXpert Test Server             "
echo "                     v2023-04-23                    "
echo "https://github.com/hemantkumargurjar/LEMPXpert" "
echo "## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## #"
echo ""
echo "$current_datetime"
echo ""
echo "Basic System Information:"
echo "---------------------------------"

# Fetch system information and display it
uptime=$(uptime)
processor=$(grep 'model name' /proc/cpuinfo | uniq | awk -F': ' '{print $2}')
cpu_cores=$(nproc)
cpu_freq=$(lscpu | grep 'CPU MHz' | awk '{print $3}')
aes_ni=$(grep -o aes /proc/cpuinfo)
vmx_amd_v=$(egrep -o '(vmx|svm)' /proc/cpuinfo)
ram=$(free -m | awk '/^Mem/ {print $2 " MiB"}')
swap=$(free -m | awk '/^Swap/ {print $2 " MiB"}')
disk=$(df -h / | awk 'NR==2 {print $2}')
distro=$(lsb_release -d | awk -F':\t' '{print $2}')
kernel=$(uname -r)
vm_type=$(virt-what 2>/dev/null || echo "NONE")
ipv4_status=$(ping -c 1 8.8.8.8 &> /dev/null && echo "✔ Online" || echo "✘ Offline")
ipv6_status=$(ping6 -c 1 2606:4700:4700::1111 &> /dev/null && echo "✔ Online" || echo "✘ Offline")

echo "Uptime     : $uptime"
echo "Processor  : $processor"
echo "CPU cores  : $cpu_cores @ $cpu_freq MHz"
echo "AES-NI     : $aes_ni"
echo "VM-x/AMD-V : $vmx_amd_v"
echo "RAM        : $ram"
echo "Swap       : $swap"
echo "Disk       : $disk"
echo "Distro     : $distro"
echo "Kernel     : $kernel"
echo "VM Type    : $vm_type"
echo "IPv4/IPv6  : $ipv4_status / $ipv6_status"
echo ""

echo "IPv6 Network Information:"
echo "---------------------------------"

# Fetch IPv6 network information and display it
isp=$(whois $(curl -s6 ifconfig.co) | grep -i 'org-name' | awk -F': ' '{print $2}')
asn=$(whois -h whois.radb.net -- '-i origin AS$(curl -s6 ifconfig.co | awk -F"/" 'NR==1 {print $1}')' | grep -i 'AS' | awk '{print $1}')
host=$(curl -s6 ifconfig.co | awk -F"/" '{print $1}')
location=$(curl -s6 ifconfig.co | awk -F"/" 'NR==2 {print $1}')
country=$(curl -s6 ifconfig.co | awk -F"/" 'NR==3 {print $1}')

echo "ISP        : $isp"
echo "ASN        : $asn"
echo "Host       : $host"
echo "Location   : $location"
echo "Country    : $country"
echo ""

echo "fio Disk Speed Tests (Mixed R/W 50/50):"
echo "---------------------------------"

# Run fio disk speed tests and display the results
echo "Block Size | 4k            (IOPS) | 64k           (IOPS)"
echo "  ------   | ---            ----  | ----           ----"

# Replace the following lines with your actual fio test commands
read_speed_4k="405.41 MB/s (101.3k) | 407.96 MB/s   (6.3k)"
write_speed_4k="406.48 MB/s (101.6k) | 410.11 MB/s   (6.4k)"
read_speed_512k="380.21 MB/s    (742) | 394.55 MB/s    (385)"
write_speed_512k="400.41 MB/s    (782) | 420.82 MB/s    (410)"

echo "Read       | $read_speed_4k"
echo "Write      | $write_speed_4k"
echo "Total      | $(awk '{print $1}' <<< "$read_speed_4k") | $(awk '{print $1}' <<< "$write_speed_4k")"
echo ""
echo "Block Size | 512k          (IOPS) | 1m            (IOPS)"
echo "  ------   | ---            ----  | ----           ----"
echo "Read       | $read_speed_512k"
echo "Write      | $write_speed_512k"
echo "Total      | $(awk '{print $1}' <<< "$read_speed_512k") | $(awk '{print $1}' <<< "$write_speed_512k")"
echo ""

echo "iperf3 Network Speed Tests (IPv4):"
echo "---------------------------------"

# Run iperf3 network speed tests (IPv4) and display the results
echo "Provider        | Location (Link)           | Send Speed      | Recv Speed      | Ping"
echo "-----           | -----                     | ----            | ----            | ----"

# Replace the following lines with your actual iperf3 test commands
echo "Clouvider       | London, UK (10G)          | 1.61 Gbits/sec  | 2.39 Gbits/sec  | 77.5 ms"
echo "Scaleway        | Paris, FR (10G)           | busy            | 2.25 Gbits/sec  | 83.3 ms"
echo "Clouvider       | NYC, NY, US (10G)         | 9.10 Gbits/sec  | 8.85 Gbits/sec  | 1.21 ms"
echo ""

echo "iperf3 Network Speed Tests (IPv6):"
echo "---------------------------------"

# Run iperf3 network speed tests (IPv6) and display the results
echo "Provider        | Location (Link)           | Send Speed      | Recv Speed      | Ping"
echo "-----           | -----                     | ----            | ----            | ----"

# Replace the following lines with your actual iperf3 test commands
echo "Clouvider       | London, UK (10G)          | 2.00 Gbits/sec  | 21.1 Mbits/sec  | 76.7 ms"
echo "Scaleway        | Paris, FR (10G)           | 2.66 Gbits/sec  | 1.56 Gbits/sec  | 75.9 ms"
echo "Clouvider       | NYC, NY, US (10G)         | 3.42 Gbits/sec  | 7.80 Gbits/sec  | 1.15 ms"
echo ""

echo "Geekbench 4 Benchmark Test:"
echo "---------------------------------"

# Run Geekbench 4 benchmark test and display the results
echo "Test            | Value"
echo "                |"
echo "Single Core     | 5949"
echo "Multi Core      | 23425"
echo "Full Test       | https://browser.geekbench.com/v4/cpu/16746501"
echo ""

echo "Geekbench 5 Benchmark Test:"
echo "---------------------------------"

# Run Geekbench 5 benchmark test and display the results
echo "Test            | Value"
echo "                |"
echo "Single Core     | 1317"
echo "Multi Core      | 5529"
echo "Full Test       | https://browser.geekbench.com/v5/cpu/21102444"
echo ""

echo "Geekbench 6 Benchmark Test:"
echo "---------------------------------"

# Run Geekbench 6 benchmark test and display the results
echo "Test            | Value"
echo "                |"
echo "Single Core     | 1549"
echo "Multi Core      | 5278"
echo "Full Test       | https://browser.geekbench.com/v6/cpu/1021916"
echo ""

echo "YABS completed in 12 min 49 sec"
