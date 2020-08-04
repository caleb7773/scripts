#!/bin/bash
cd /opt/easy-rsa/easyrsa3/
read -p "What is the server CN : " commonname
./easyrsa build-server-full $commonname nopass
mkdir /tmp/$commonname
######################################################
#You need to remove the top 66 lines in a server cert#
######################################################
sed -i 1,66d pki/issued/$commonname.crt
sed -i '1s;^;<cert>\n;' pki/issued/$commonname.crt
sudo tee -a pki/issued/$commonname.crt <<EOF
</cert>
EOF
sed -i '1s;^;<key>\n;' pki/private/$commonname.key
sudo tee -a pki/private/$commonname.key <<EOF
</key>
EOF
cp pki/ca.crt /tmp/$commonname/
sed -i '1s;^;<ca>\n;' /tmp/$commonname/ca.crt
sudo tee -a /tmp/$commonname/ca.crt <<EOF
</ca>
EOF
cp pki/issued/$commonname.crt /tmp/$commonname/
cp pki/private/$commonname.key /tmp/$commonname/
cd /tmp/$commonname/
cat ca.crt $commonname.crt $commonname.key > /tmp/$commonname/$commonname.inline
tar cvf $commonname.tar /tmp/$commonname/$commonname.inline
rm /tmp/$commonname/$commonname.crt
rm /tmp/$commonname/$commonname.key
rm /tmp/$commonname/ca.crt
clear
echo ' '
echo ' '
tar tvf /tmp/$commonname/$commonname.tar | cut -d ' ' -f6 | cut -d '/' -f2
echo ' '
