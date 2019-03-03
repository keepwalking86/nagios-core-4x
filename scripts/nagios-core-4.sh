#!/bin/bash
#Write by KeepWalking
#Requerement: CentOS 7, Nagios Core 4x

NAGIOS_VERSION="nagios-4.4.1"
#https://github.com/NagiosEnterprises/nagioscore/releases
NAGIOS_PATH="https://github.com/NagiosEnterprises/nagioscore/releases/download/nagios-4.4.1/nagios-4.4.1.tar.gz"
NAGIOS_USER="nagiosadmin"
NAGIOS_PASS="nagiosadmin"

#Disable Selinux
setenforce 0
sed -i 's/SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config

#Installing libraries and dependent packages
yum -y install gcc glibc glibc-common wget unzip httpd php gd gd-devel openssl openssl-devel perl gettext automake autoconf net-snmp net-snmp-utils epel-release gettext net-snmp net-snmp-utils perl-Net-SNMP
yum -y groupinstall "Development Tools"

###Installing the Nagios Core###
#Downloading
cd /opt
wget -O $NAGIOS_VERSION.tar.gz $NAGIOS_PATH && tar xzf $NAGIOS_VERSION.tar.gz
#Compile
cd /opt/${NAGIOS_VERSION}
./configure
make all
#Create User And Group
useradd nagios
groupadd nagcmd
usermod -a -G nagcmd nagios
usermod -G nagcmd apache
#Install Binaries
make install
#Install Service / Daemon
make install-init
systemctl enable nagios.service
systemctl enable httpd.service
#Install Command Mode
make install-commandmode
#Install Configuration Files
make install-config
#Install Apache Config Files
make install-webconf

#Create nagiosadmin User Account to login nagios
htpasswd -b -c /usr/local/nagios/etc/htpasswd.users ${NAGIOS_USER} ${NAGIOS_PASS}

#Start Apache Web Server and Nagios
systemctl start httpd.service
systemctl start nagios.service

#Configure Firewall
firewall-cmd --zone=public --add-port=80/tcp --permanent
firewall-cmd --reload

#####Installing Nagios Plugin#####
cd /opt
wget --no-check-certificate https://nagios-plugins.org/download/nagios-plugins-2.2.1.tar.gz
tar zxf nagios-plugins-2.2.1.tar.gz
cd /opt/nagios-plugins-2.2.1		
./configure --with-nagios-user=nagios --with-nagios-group=nagios --with-openssl
make
make install

#####Installing check_nrpe plugin to monitor Linux/Unix
#https://github.com/NagiosEnterprises/nrpe/releases
cd /opt
wget --no-check-certificate https://github.com/NagiosEnterprises/nrpe/releases/download/nrpe-3.2.1/nrpe-3.2.1.tar.gz
tar zxvf nrpe-3.2.1.tar.gz
cd /opt/nrpe-3.2.1/
./configure --enable-command-args
make all
make install

### Access to Nagios Web Interface
IP_ADDR=` ip route get 1.1.1.1 | grep -oP 'src \K\S+'`
echo -e "Access to Nagios Web Interface: http://$IP_ADDR/nagios
             Username: ${NAGIOS_USER}
             Password: ${NAGIOS_PASS}"
