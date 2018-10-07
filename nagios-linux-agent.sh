#!/bin/bash
#Script for installing nagios linux client (Ubuntu/CentOS)
#This script requires root privileges, otherwise could run as a sudo user who has got root privileges

NAGIOS_SERVER=192.168.10.100

#Installing required tools
if [ -f /etc/debian_version ]; then
    echo "Installing prerequisite packages"
    #NRPE
    apt-get update
    apt-get install -y autoconf automake gcc libc6 libmcrypt-dev make libssl-dev wget openssl
    #Nagios Plugin
    apt-get install -y libmcrypt-dev bc gawk dc build-essential snmp libnet-snmp-perl gettext
    ##Firewall
    mkdir -p /etc/ufw/applications.d
    sh -c "echo '[NRPE]' > /etc/ufw/applications.d/nagios"
    sh -c "echo 'title=Nagios Remote Plugin Executor' >> /etc/ufw/applications.d/nagios"
    sh -c "echo 'description=Allows remote execution of Nagios plugins' >> /etc/ufw/applications.d/nagios"
    sh -c "echo 'ports=5666/tcp' >> /etc/ufw/applications.d/nagios"
    ufw allow NRPE
    ufw reload
else
    if [ -f /etc/redhat-release ]; then
        echo "Installing prerequisite packages"
        #Nagios Plugin
        yum install -y gcc glibc glibc-common make gettext automake autoconf wget openssl-devel net-snmp net-snmp-utils epel-release perl-Net-SNMP
        #NRPE
        yum install -y openssl openssl-devel
        #Configure Firewall
        firewall-cmd --zone=public --add-port=5666/tcp --permanent
        firewall-cmd --reload
    else
        echo "Distro hasn't been supported by this script"
        exit 1;
    fi
fi

##INSTALLING NRPE
#Downloading the source
cd /opt
wget --no-check-certificate -O nrpe.tar.gz https://github.com/NagiosEnterprises/nrpe/archive/nrpe-3.2.1.tar.gz
tar xzf nrpe.tar.gz
#Compile
cd /opt/nrpe-nrpe-3.2.1/
./configure --enable-command-args
make all
#Create User And Group
make install-groups-users
#Install Binaries
make install
#Install Configuration Files
make install-config
#Update Services File
echo >> /etc/services
echo '# Nagios services' >> /etc/services
echo 'nrpe    5666/tcp' >> /etc/services
#Install Service / Daemon
make install-init
systemctl enable nrpe.service
#Update Configuration File
sed -i "/^allowed_hosts=/s/$/,${NAGIOS_SERVER}/" /usr/local/nagios/etc/nrpe.cfg
sed -i 's/^dont_blame_nrpe=.*/dont_blame_nrpe=1/g' /usr/local/nagios/etc/nrpe.cfg
#Start Service / Daemon
systemctl start nrpe.service
systemctl enable nrpe.service

#INSTALLING NAGIOS-PLUGIN
#Downloading the source
cd /opt
wget --no-check-certificate -O nagios-plugins.tar.gz https://github.com/nagios-plugins/nagios-plugins/archive/release-2.2.1.tar.gz
tar zxf nagios-plugins.tar.gz
#Compile + Install
cd /opt/nagios-plugins-release-2.2.1/
./tools/setup
./configure
make
make install
