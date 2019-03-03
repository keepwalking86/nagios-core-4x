#!/bin/bash
####################################
###### Bandwidth Usage Calculator #
#####   by Stefano Bruno         ##
####    stefanobr1@gmail.com    ###
###     Requirements           ####
##      - bc 		      #####
#       Version: 0.1         ######
###################################

usage="
Usage: check_speed_test.sh -s packet_size -d local_directory -r remote directory

This script calculate speed in downlod and upload from local server to remote server.
The remote server is the first parameter ($hostaddress) and you must only to create service related to an hostaddress or hostgroup

####List of Available Parameters
-s Packet size (10240=10Mb, 102400=100Mb)
-d Local directory where you want to create file for speed test. The directory must to be exist - ex. /tmp/speed_test/
-r Remote directory where you want to create file for speed test. The directory must to be exist - ex. /tmp/speed_test/
-h Print this help screen
"

while getopts H:s:d:r:help:h option;
do
        case $option in
		H) hostaddress=$OPTARG;;
		s) size=$OPTARG;;
		d) local_directory=$OPTARG;;
		r) remote_directory=$OPTARG;;
                h) help=1;;
        esac
done

#Check parameters function
check()
{

if [ "$help" == "1" ]
then
echo "$usage"
exit;
fi

if  [ -z "$hostaddress" ] || [ -z "$size" ] || [ -z "$local_directory" ] || [ -z "$remote_directory" ] && [ "$help" != "1" ]
then
        echo "
** Hostaddress, size, local directory and remote directory parameters are mandatory"
        echo "$usage"
        exit;
fi

}
check

#Create test file
dd if=/dev/zero of=$local_directory/scp_test_file bs=1024 count=$size > /dev/null 2>&1
#Time in seconds (download)
down=$( { \time -f "%e" scp $local_directory/scp_test_file root@$hostaddress:$remote_directory/scp_test_file > /dev/null ; } 2>&1 )
#Time in seconds (upload)
up=$( { \time -f "%e" scp root@$hostaddress:$remote_directory/scp_test_file $local_directory/scp_test_file_down > /dev/null ; } 2>&1 )
#Download Speed in bits
down_speed_bits=`echo "scale=3;(10/$down*8*1048576)" | bc`
#Upload Speed in bits
up_speed_bits=`echo "scale=3;(10/$up*8*1048576)" | bc`
echo "D: $down_speed_bits bits/s - U: $up_speed_bits bits/s |dload="$down_speed_bits"bits/s uload="$up_speed_bits"bits/s"
