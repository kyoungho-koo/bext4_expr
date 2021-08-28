#!/bin/sh

# Device
# - /dev/sdb: SAMSUNG 860PRO 512GB
# - /dev/nvme0n1: SAMSUNG 970PRO 512GB
VERSION="$(uname -r| awk -F '-' '{print $1}')"
EXTRA_VERSION="$(uname -r| awk -F '-' '{print $2}')"
DEBUG="$(uname -r | awk -F '-' '{print $3}')"


#BENCHMARK="dd"
#BENCHMARK="filebench-varmail"
#BENCHMARK="filebench-varmail-perthreaddir"
BENCHMARK="filebench-varmail-latency"
#BENCHMARK="filebench-varmail-split16"
#BENCHMARK="dbench-client"
#BENCHMARK="sysbench"
#BENCHMARK="mdtest"
#BENCHMARK="ycsb-a"


#	/dev/sda	840PRO
#	/dev/sdd	850PRO
#	/dev/nvme0n1	970pro
#	/dev/nvme1n1	Intel 750 series
#	/dev/nvme2n1	Intel Optane 900P
#	/dev/md5	Software RAID 5
#	/dev/md0 	Software RAID 0
#	/dev/sdj 	Samsung SM883 (super cap)
#	/dev/sdm 	Hardware RAID 5
#	/dev/sdn 	Hardware RAID 0
#	ramdisk 	RAMDISK
#DEV=(/dev/sdd /dev/nvme1n1 /dev/nvme2n1)
DEV=(/dev/sda /dev/sdd /dev/nvme1n1 /dev/nvme2n1)




#	0	def
#	1	debug-def
#	2	c2j
#	3	debug-c2j
#EXT4_PSP=(0 1000 2000 3000 4000 5000 6000)
EXT4_PSP=(0 2)
BEXT4_PSP=(0 223)


#FTRACE_PATH=/sys/kernel/debug/tracing

NUM_THREADS=(32)
#NUM_THREADS=(16)
ITER=1
MNT=/mnt



VERSION_PATH="raw_data"
if [ "$EXTRA_VERSION" = "barrier" ]
then
	PSP=${BEXT4_PSP[@]}
	VERSION_PATH=${VERSION_PATH}"/bext4"
else
	PSP=${EXT4_PSP[@]}
	VERSION_PATH=${VERSION_PATH}"/ext4"
	DEBUG="$EXTRA_VERSION"
fi 
echo "$VERSION_PATH"
