#!/bin/bash

read -p "What is your VPN Name? " vpn_name
read -p "What is the remote IP? " vpn_remote_ip
read -p "What port do you want to use for OpenVPN? " vpn_port

sudo apt-get install openvpn

sudo touch /etc/openvpn/${vpn_name}-client.conf

#########################################################
#########################################################
###                                                   ###
###          THIS IS YOUR CONFIG FILE EDIT IT!        ###
###                                                   ###
#########################################################
#########################################################
sudo tee /etc/openvpn/${vpn_name}-client.conf <<EOF
#This directive creates a layer 3 (tun) OpenVPN tunnel
dev-type tun
dev server0
#This directive sets the topology of the VPN to p2p (site-to-site).
topology p2p
#Either end of the tunnel must have an IP address, so we use ifconfig <local> <remote> to set them. These should be reversed from how they are set up in the server since the command is ifconfig local remote, not ifconfig server client.
ifconfig 10.1.0.2 10.1.0.1
#The client needs to know where to connect to find the server.
remote ${vpn_remote_ip} vpn_port
#Creating a log is useful for troubleshooting.
log bear-client.log
#use keepalives
keepalive 10 60
EOF

sudo iptables -I OUTPUT 1 -p udp -m udp --dport ${vpn_port} -m comment --comment "Outgoing ${vpn_name} vpn traffic to ${vpn_remote_ip}" -j ACCEPT

sudo systemctl start openvpn@${vpn_name}-client
ip a


echo "alias ${vpn_name}vpnon=\"sudo systemctl start openvpn@${vpn_name}-client\"" | tee -a ~/.bashrc
echo "alias ${vpn_name}vpnoff=\"sudo systemctl stop openvpn@${vpn_name}-client\"" | tee -a ~/.bashrc
source ~/.bashrc
echo "You have created the aliases"
echo "${vpn_name}vpnon which will turn on your ${vpn_name} VPN"
echo "${vpn_name}vpnoff which will turn off your ${vpn_name} VPN"




