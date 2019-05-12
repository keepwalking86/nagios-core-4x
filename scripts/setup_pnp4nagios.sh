#!/bin/bash
#Install & configure PNP4Nagios on CentOS7/Ubuntu-16.04+

#Downloading the Source
cd /tmp
wget -O pnp4nagios.tar.gz https://github.com/lingej/pnp4nagios/archive/0.6.26.tar.gz
tar xzf pnp4nagios.tar.gz
cd pnp4nagios-0.6.26

#Install requirement tools and PNP4Nagios
if [ -f /etc/debian_version ]; then
    echo "Installing prerequisite packages"
    apt-get update
    apt-get install -y rrdtool librrd-simple-perl php-gd php-xml
    #Configure
    ./configure --with-httpd-conf=/etc/apache2/sites-enabled
else
    if [ -f /etc/redhat-release ]; then
        echo "Installing prerequisite packages"
        yum install -y rrdtool perl-rrdtool perl-Time-HiRes php-gd
	./configure
    else
        echo "Distro hasn't been supported by this script"
        exit 1;
    fi
fi
#Compile and Install PNP4Nagios
make all
make install
make install-webconf
make install-config
make install-init

#Configure & Start Service / Daemon
systemctl daemon-reload
systemctl enable npcd.service
systemctl start npcd.service
systemctl restart httpd.service

#Remove Environment test file
rm -f /usr/local/pnp4nagios/share/install.php

#Processing performance data
sed -i '/process_performance_data/c\process_performance_data=1' /usr/local/nagios/etc/nagios.cfg
cat >>/usr/local/nagios/etc/nagios.cfg<<EOF
#service performance data

service_perfdata_file=/usr/local/pnp4nagios/var/service-perfdata
service_perfdata_file_template=DATATYPE::SERVICEPERFDATA\tTIMET::\$TIMET$\tHOSTNAME::\$HOSTNAME$\tSERVICEDESC::\$SERVICEDESC$\tSERVICEPERFDATA::\$SERVICEPERFDATA$\tSERVICECHECKCOMMAND::\$SERVICECHECKCOMMAND$\tHOSTSTATE::\$HOSTSTATE$\tHOSTSTATETYPE::\$HOSTSTATETYPE$\tSERVICESTATE::\$SERVICESTATE$\tSERVICESTATETYPE::\$SERVICESTATETYPE$
service_perfdata_file_mode=a
service_perfdata_file_processing_interval=15
service_perfdata_file_processing_command=process-service-perfdata-file

#host performance data starting with Nagios
 
host_perfdata_file=/usr/local/pnp4nagios/var/host-perfdata
host_perfdata_file_template=DATATYPE::HOSTPERFDATA\tTIMET::\$TIMET$\tHOSTNAME::\$HOSTNAME$\tHOSTPERFDATA::\$HOSTPERFDATA$\tHOSTCHECKCOMMAND::\$HOSTCHECKCOMMAND$\tHOSTSTATE::\$HOSTSTATE$\tHOSTSTATETYPE::\$HOSTSTATETYPE$
host_perfdata_file_mode=a
host_perfdata_file_processing_interval=15
host_perfdata_file_processing_command=process-host-perfdata-file
EOF

#Define commands (process-service-perfdata-file & process-host-perfdata-file)
cat >>/usr/local/nagios/etc/objects/commands.cfg<<EOF
#PERFORMANCE DATA COMMANDS with PNP4Nagios
define command{
       command_name    process-service-perfdata-file
       command_line    /bin/mv /usr/local/pnp4nagios/var/service-perfdata /usr/local/pnp4nagios/var/spool/service-perfdata.\$TIMET$
}

define command{
       command_name    process-host-perfdata-file
       command_line    /bin/mv /usr/local/pnp4nagios/var/host-perfdata /usr/local/pnp4nagios/var/spool/host-perfdata.\$TIMET$
}
EOF

#Define templates (host-pnp & srv-pnp)
cat >>/usr/local/nagios/etc/objects/templates.cfg<<EOF
#PNP4Nagios
define host {
   name       host-pnp
   action_url /pnp4nagios/index.php/graph?host=\$HOSTNAME$&srv=_HOST_' class='tips' rel='/pnp4nagios/index.php/popup?host=\$HOSTNAME$&srv=_HOST_
   register   0
}

define service {
   name       srv-pnp
   action_url /pnp4nagios/index.php/graph?host=\$HOSTNAME$&srv=\$SERVICEDESC$' class='tips' rel='/pnp4nagios/index.php/popup?host=\$HOSTNAME$&srv=\$SERVICEDESC$
   register   0
}
EOF
