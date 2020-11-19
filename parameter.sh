#!/bin/sh

# Device
# - /dev/sdb: SAMSUNG 860PRO 512GB
# - /dev/nvme0n1: SAMSUNG 970PRO 512GB

VERSION="$(uname -r| awk -F '-' '{print $2}')"

#BENCHMARK="dd"
#BENCHMARK="filebench-varmail"
#BENCHMARK="filebench-varmail-split16"
#BENCHMARK="dbench-client"
#BENCHMARK="sysbench"
BENCHMARK="mdtest"


#	/dev/sdk	860PRO
#	/dev/nvme0n1	970pro
#	/dev/nvme1n1	Intel 750 series
#	/dev/nvme2n1	Intel Optane 900P
#	/dev/md5	Software RAID 5
#	/dev/md0 	Software RAID 0
#	/dev/sdj 	Samsung SM883 (super cap)
#	/dev/sdm 	Hardware RAID 5
#	/dev/sdn 	Hardware RAID 0
#	ramdisk 	RAMDISK
DEV=(/dev/sdm /dev/sdj /dev/nvme0n1 /dev/nvme2n1 ramdisk)




#	0	default     -----------> default
#	1	psp
#	3	psp-ifs
#	7	psp-efs
#	8 	loop
#	9 	loop psp 
#	11 	loop psp-ifs 
#	15 	loop psp-efs
#	16 	cc
#	24 	cc loop
#	25 	cc loop psp
#	27 	cc loop psp-ifs
#	31 	cc loop psp-efs
#	65 	psp pool 
#	67 	psp-ifs pool 
#	71 	psp-efs pool 
#	75 	loop psp-ifs pool 
#	79 	loop psp-efs pool 
#	87	cc psp-efs pool  --------> PP
#	89 	cc loop psp pool 
#	91 	cc loop psp-ifs pool 
#	95 	cc loop psp-efs pool
#	152 	tc2 cc           --------> TC
#	219 	tc2 cc psp-ifs pool
#	223 	tc2 cc psp-efs pool -----> ALL
EXT4_PSP=(0)
BEXT4_PSP=(0 87 152 223)


#FTRACE_PATH=/sys/kernel/debug/tracing

NUM_THREADS=(1 2 4 6 8 10 20 30 40)
ITER=1
MNT=/mnt
