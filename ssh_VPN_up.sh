#!/bin/bash
#ssh_vpn_up requires an entry in the ssh config file called eng0
echo "Current IP: $(curl -s ipinfo.io)"
USER="$(id | cut -d' ' -f1 | sed 's/uid=.*(\(.*\))/\1/g')"
GROUP="$(id | cut -d' ' -f2 | sed 's/gid=.*(\(.*\))/\1/g')"
sudo ip tuntap add dev tun0 mode tun user "${USER}" group "${GROUP}"
sudo ip address add 192.168.255.2/32 peer 192.168.255.1 dev tun0
sudo ip link set dev tun0 up
ENGIP="$(ssh -G eng0 | grep '^hostname' | awk '{print $2}')"
GWIP="$(ip route | grep default | awk '{print $3}')"
GWDEV="$(ip route | grep default | awk '{print $5}')"
sudo ip route add "${ENGIP}/32" via "${GWIP}" dev "${GWDEV}"
ssh -fqNTw 0:0 eng0
sudo ip route replace default via 192.168.255.1 dev tun0
echo "New IP: $(curl -s ipinfo.io)"
