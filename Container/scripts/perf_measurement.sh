#!/bin/bash
# This script reads ENV variables set by the Dockerfile by default. To 
# override this behaviour, specify variables with docker run -e "VAR=value". 
 
# docker run $IMAGE_ID -e "MODE=client" -e "TEST=iperf" -e "TYPE=UDP" -e "MODE=client" -e "SRC_SITE=AMS" -e "DST_SITE=PRG" -e "ADDRESS=192.168.1.1" -e "OVERLAY=none"

if [[ $MODE =~ ^(client|CLIENT)$ ]]; then
	# netperf measurement
	if [[ $TEST =~ ^(NETPERF|netperf)$ ]]; then
		# Generate timestamp (start)
		psstart=$(date +%Y%m%d%H%M%S)

		# Run performance measurement
		psresult=$(netperf -H $ADDRESS -t TCP_RR -- -O min_latency,mean_latency,p99_latency,stddev_latency | tail -n 1 | awk '{$1=$1}1' OFS=",")

		# Generate timestamp (end)
		psend=$(date +%Y%m%d%H%M%S)

		# Write log to file
		echo $psstart","$psend",$SRC_SITE,$DST_SITE," $psresult >> MSMT_$SRC_SITE_$DST_SITE_$TEST_$OVERLAY.csv

	elif [[ $TEST =~ ^(IPERF|iperf)$ ]]; then
		# Differentiate between TCP and UDP bandwith test 
		if [[ $TYPE =~ ^(UDP|udp)$ ]]; then
			# Run performance measurement & write to CSV
			iperf -c -u $ADDRESS -b 0 -y C >> /data/MSMT_$SRC_SITE_$DST_SITE_$TEST_$TYPE_$OVERLAY.csv
		else
			# Run performance measurement & write to CSV
			iperf -c $ADDRESS -y C >> /data/MSMT_$SRC_SITE_$DST_SITE_$TEST_$TYPE_$OVERLAY.csv
		fi
	else
		exit
	fi

else
	if [[ $TEST =~ ^(NETPERF|netperf)$ ]]; then
		netserver
	else
		if [[ $TYPE =~ ^(UDP|udp)$ ]]; then
			# Run server as daemon in UDP mode
			iperf -s -D -u
		else
			# Run server as daemon in TCP mode (default)
			iperf -s -D
		fi 
	fi
fi



