#!/bin/bash
cd /opt/easy-rsa/easyrsa3/
read -p "What is the client CN : " commonname
./easyrsa build-client-full $commonname nopass
mkdir /tmp/$commonname
./easyrsa gen-crl 
cp pki/crl.pem /tmp/$commonname/
openvpn --genkey --secret ta.key
echo "<tls-crypt>" | sudo tee ./ta.inline.key
sed -i 1,3d ./ta.key
echo "</tls-crypt>" | sudo tee -a /tmp/$commonname/ta.key
cat ./ta.key | sudo tee -a ./ta.inline.key
mv ./ta.inline.key /tmp/$commonname/ta.key
######################################################
#You need to remove the top 64 lines in a client cert#
######################################################


sed -i 1,64d pki/issued/$commonname.crt
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
cat ca.crt $commonname.crt $commonname.key ta.key > /tmp/$commonname/$commonname.inline
tar cvf $commonname.tar /tmp/$commonname/$commonname.inline /tmp/$commonname/crl.pem
rm /tmp/$commonname/$commonname.crt
rm /tmp/$commonname/$commonname.key
rm /tmp/$commonname/ca.crt
rm /tmp/$commonname/ta.key
rm /tmp/$commonname/crl.pem
clear
echo ' '
echo ' '
tar tvf /tmp/$commonname/$commonname.tar | cut -d ' ' -f6 | cut -d '/' -f2
echo ' ' 
