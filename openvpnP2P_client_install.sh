#!/bin/bash

read -p "What is your VPN Name? " vpn_name
read -p "What is the remote IP? " vpn_remote_ip

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
remote ${vpn_remote_ip}
#Creating a log is useful for troubleshooting.
log bear-client.log
#use keepalives
keepalive 10 60
EOF

sudo systemctl start openvpn@${vpn_name}-client
ip a
