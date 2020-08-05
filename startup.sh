#!/bin/bash
trap 'echo "Cleaning up!"; shred -u /tmp/users; exit' INT
#####################################################
enter_continue() {
	echo ' '
	read -p 'Press ENTER to continue....'
	clear
}
ssh_port_input() {
	while :; do
		left=$(echo '>>>>')
		right=$(echo '<<<<')
		echo 'Which port would you like SSH to run on?'
		read -p "SSH Port (2000 - 65000) : " ssh_port_num
		echo ' '
  		[[ $ssh_port_num =~ ^[0-9]+$ ]] || { echo "Are you high!? ${left} ${ssh_port_num} ${right} is not a valid port...."; echo ' '; continue; }
  	if ((ssh_port_num >= 2000 && ssh_port_num <= 65000)); then
		echo ' '
		echo "You chose to run SSH on port $ssh_port_num"
		echo ' '
   		read -p "Press Enter to continue..." 
		break
  	else
		echo ' '
   		 echo "Number out of range, try again"
		 echo ' '
  	fi
done	
}
username_input() {
	echo 'You need to create a user.'
	read -p "Enter username : " username
}
username_check() {
	egrep "^$username" /etc/passwd >/dev/null
	while [ $? -eq 0 ]
	do 
		echo ' '
		echo "${username} is already a user!"
		echo ' '
		username_input
	done
}
password_input() {
	echo "What password do you want to use for ${username}?"
	read -sp "Enter password : " password
	echo ' '
	read -sp "Please confirm : " password2
	echo ' '
}
password_check() {
	while [ ${password:-1} != ${password2:-2} ]
	do 
		echo "Your entries do not match!"
		echo ' '
		password_input
	done
}
user_creation() {
	pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
        sudo useradd -m -s /bin/bash -G sudo -p "$pass" "$username"
        echo "${username} has been added to the system!"
	echo ' '
	echo "${username} is a root user!"
	echo ' '
	read -p "Press ENTER to continue..."
}
clear && echo ' ' && echo "Hello! First can I get root access please?" && echo ' '
sudo ls -l /tmp >/dev/null
clear && echo ' '
ssh_port_input
clear && echo ' '
username_input
username_check
clear && echo ' '
password_input
password_check
clear && echo ' '
user_creation
clear && echo ' '
#####################
#IPTABLES BUILD OUT #
#####################
sudo iptables -A INPUT -p icmp -j ACCEPT
sudo iptables -A INPUT -p tcp -m tcp --dport ${ssh_port_num} -j ACCEPT
sudo iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A INPUT -m conntrack --ctstate INVALID -j DROP
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED -j ACCEPT
sudo iptables -A OUTPUT -m conntrack --ctstate INVALID -j DROP
sudo iptables -A OUTPUT -p tcp -m multiport --dport 53,80,443 -j ACCEPT
sudo iptables -A OUTPUT -p udp -m multiport --dport 53,123 -j ACCEPT
sudo iptables -A OUTPUT -o lo -j ACCEPT
sudo iptables -A OUTPUT -p icmp -j ACCEPT
sudo iptables -P OUTPUT DROP
sudo iptables -P INPUT DROP
#############################################################################
#Installs iptables-persistent without screen prompt for saving IPv4 and IPv6#
#############################################################################
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections
sudo apt-get -y install iptables-persistent
sudo iptables-save | sudo tee /etc/iptables/rules.v4
clear
sudo iptables -nvL
echo ' '
echo ' IPTABLES built!'
enter_continue
########################################
#Beginning Program Update and Downloads#
########################################
sudo apt update -y && sudo apt upgrade -y && sudo apt dist-upgrade -y
echo ' '
echo ' System updated, upgraded and ready to roll!'
enter_continue
sudo apt install chkrootkit rkhunter -y
echo ' '
echo ' CHKRootKit and RKHunter Installed!'
enter_continue
sudo apt install clamav clamav-daemon -y
echo ' '
echo ' ClamAV installed with Daemon!'
enter_continue
sudo apt install apparmor apparmor-utils apparmor-profiles -y
echo ' '
echo ' AppArmor Installed with Utils and Profiles!'
enter_continue
sudo apt install htop -y
echo ' '
echo ' HTOP Installed!'
enter_continue
sudo apt install tree -y
echo ' '
echo ' Tree Installed!'
enter_continue
sudo apt install mlocate -y
echo ' '
echo ' MLocate Installed!'
enter_continue
sudo apt install cryptsetup -y
echo ' '
echo ' CryptSetup Installed!'
enter_continue
sudo apt install nmap -y
echo ' '
echo ' NMAP Installed!'
enter_continue
sudo apt install fail2ban -y
echo ' '
echo ' Fail2Ban Installed!'
enter_continue
sudo apt install tmux -y
echo ' '
echo ' Tmux Installed!'
enter_continue

##################################
#Disables IPv6 routing on the box#
##################################
sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="ipv6.disable=1 /g' /etc/default/grub
sudo sed -i 's/GRUB_CMDLINE_LINUX="/GRUB_CMDLINE_LINUX="ipv6.disable=1 /g' /etc/default/grub
sudo update-grub
################################################
#Changes colors for Prompt and disables history#
################################################
echo 'export PS1="\[$(tput setaf 3; tput bold; tput rev)\]\u@\h:\w\$\[$(tput sgr0)\] "' >> ~/.bashrc
source ~/.bashrc
###############################
#Changes the SSH port to 20022#
###############################
sudo sed -i "s/#Port 22/Port ${ssh_port_num}/g" /etc/ssh/sshd_config
sudo sed -i "s/#PermitRootLogin/PermitRootLogin/g" /etc/ssh/sshd_config
sudo systemctl restart ssh
#####################
#Enable IPv4 Routing#
#####################
sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf && sudo sysctl -p
###########################################
#Setting up Fail2ban for SSH on port 20022#
###########################################
sudo cp /etc/fail2ban/fail2ban.conf /etc/fail2ban/fail2ban.local
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
#############################################################
#Removing the existing SSH commands from the jail.local file#
#############################################################
sudo sed -i 's/^\[sshd\]//g' /etc/fail2ban/jail.local
sudo sed -i 's/^port    = ssh//g' /etc/fail2ban/jail.local
sudo sed -i 's/^logpath = %(sshd_log)s//g' /etc/fail2ban/jail.local
sudo sed -i 's/^backend = %(sshd_backend)s//g' /etc/fail2ban/jail.local
##################################################
#Appending the new SSH config into the jail.local#
##################################################
sudo tee -a /etc/fail2ban/jail.local <<EOF

[sshd]
port = ${ssh_port_num}
enabled = true
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 120
EOF
#############################
#Restarting Fail2Ban and SSH#
#############################
sudo systemctl restart fail2ban
sudo systemctl restart ssh
#########################
#Installs Lynis from GIT#
#########################
sudo apt install git -y
echo ' '
echo ' GIT Installed!'
enter_continue
sudo su -c "cd && git clone https://github.com/CISOfy/lynis.git && cd lynis/ && ./lynis audit system --quiet"
#################################
#Starts Aide and builds database#
#Run at the end after all change#
#################################
sudo apt install aide -y
echo ' '
echo ' AIDE Installed!'
enter_continue
###################################
#Displays all users who can log in#
###################################
echo 'Users who can log onto your machine:' >> /tmp/users
echo ' ' >> /tmp/users
cat /etc/passwd | grep 'bin/bash' | cut -d ':' -f1 | tee -a /tmp/users
echo ' ' >> /tmp/users
echo ' ' >> /tmp/users
########################################
#Displays all users who are SUDO admins#
########################################
echo 'Users who can SUDO on your machine:' >> /tmp/users
echo ' ' >> /tmp/users
grep 'sudo' /etc/group | cut -d ':' -f4 | tee -a /tmp/users
clear
##################
#Restarts the box#
##################
cat /tmp/users
echo ' '
echo ' '
echo 'Now you know who has access to your box.'
sudo shred -u /tmp/users
enter_continue
echo 'Once AIDE completes building the database'
echo '     your box will restart itself'
echo '     and you will be super secure!'
echo ' '
##################################
#Builds AIDE databse and moves it#
##################################
sudo aideinit
sudo mv /var/lib/aide/aide.db.nw /var/lib/aide/aide.db
echo ' '
echo 'You are now secure!'
echo ' '
echo 'The box will now reboot!'
enter_continue
sudo reboot
