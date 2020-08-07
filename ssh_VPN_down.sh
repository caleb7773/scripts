#!/bin/bash
#ssh_vpn_down
echo "Current IP: $(curl -s ipinfo.io)"
ENGIP="$(ssh -G eng0 | grep '^hostname' | awk '{print $2}')"
sudo ip route del "${ENGIP}"
sudo ip link set dev tun0 down
sudo killall ssh
sudo ip tuntap delete dev tun0 mode tun
echo "Your current IP: $(curl -s ipinfo.io)"
