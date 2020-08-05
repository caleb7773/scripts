#!/bin/bash

read -p "What is your VPN Name? " vpn_name

sudo apt-get install openvpn

sudo touch /etc/openvpn/${vpn_name}-server.conf
#########################################################
#########################################################
###                                                   ###
###          THIS IS YOUR CONFIG FILE EDIT IT!        ###
###                                                   ###
#########################################################
#########################################################
sudo tee /etc/openvpn/${vpn_name}-server.conf <<EOF
#This directive creates a layer 3 (tun) OpenVPN tunnel
dev-type tun
dev client0
#This directive sets the topology of the VPN to p2p (site-to-site).
topology p2p
#Either end of the tunnel must have an IP address, so we use ifconfig <local> <remote> to set them.
#Change these if you want to
ifconfig 10.1.0.1 10.1.0.2
#Creating a log is useful for troubleshooting.
log ${vpn_name}-server.log
#By default, OpenVPN will shut down the tunnel after 2 minutes if no traffic is being passed through it. We can keep it open indefinitely with keepalive.
#We are specifying that OpenVPN should ping the other side of the tunnel every 10 seconds and if a response isn't received after 60 seconds, restart the tunnel.
keepalive 10 60
EOF

sudo systemctl start openvpn@${vpn_name}-server
ip a
echo ' '
vpn_remote_ip=$(curl -s ipinfo.io)
echo "Your remote IP is ${vpn_remote_ip}"

echo "alias ${vpn_name}vpnon=\"sudo systemctl start openvpn@${vpn_name}-server\"" | tee -a ~/.bashrc
echo "alias ${vpn_name}vpnoff=\"sudo systemctl stop openvpn@${vpn_name}-server\"" | tee -a ~/.bashrc
echo "You have created the aliases"
echo "${vpn_name}vpnon which will turn on your ${vpn_name} VPN"
echo "${vpn_name}vpnoff which will turn off your ${vpn_name} VPN"
