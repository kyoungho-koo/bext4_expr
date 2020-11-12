#!/bin/sh

# Device
# - /dev/sdb: SAMSUNG 860PRO 512GB
# - /dev/nvme0n1: SAMSUNG 970PRO 512GB

VERSION="$(uname -r| awk -F '-' '{print $2}')"

#BENCHMARK="dd"
BENCHMARK="filebench-varmail"
#BENCHMARK="filebench-varmail-split16"
#BENCHMARK="dbench-client"
#BENCHMARK="sysbench"
#BENCHMARK="mdtest"


#	/dev/sdb	860PRO
#	/dev/sdk	860PRO
#	/dev/nvme0n1	970pro
#	/dev/nvme2n1	Optane
#	/dev/md5	Software RAID 5
#	/dev/md0 	Software RAID 0
#	/dev/sdj 	Single SSD
#	/dev/sdm 	Hardware RAID 5
#	/dev/sdn 	Hardware RAID 0
#	ramdisk 	Hardware RAID 0
#DEV=(/dev/sdk /dev/sdm /dev/sdj /dev/nvme0n1 /dev/nvme1n1 /dev/nvme2n1)
DEV=(/dev/sdm /dev/sdj /dev/nvme0n1 /dev/nvme2n1)


MNT=/mnt


#	0	default
#	1	psp
#	3	psp-ifs
#	7	psp-full
#	8 	loop
#	9 	loop-psp-ifs 
#	11 	loop-psp-ifs 
#	15 	loop-psp-full
#	16 	count
#	24 	count-loop
#	25 	count-loop-psp
#	27 	count-loop-psp-ifs
#	31 	count-loop-psp-full
#	47 	debug
#	48 	debug
#	63 	debug
#	65 	psp-pool 
#	67 	psp-ifs-pool 
#	71 	psp-efs-pool 
#	75 	loop-psp-ifs-pool 
#	79 	loop-psp-efs-pool 
#	89 	count-loop-psp-pool 
#	91 	count-loop-psp-ifs-pool 
#	95 	count-loop-psp-efs-pool
#	152 	try-commit
#	219 	try-commit
#	223 	try-commit
#PSP=(0 1 3 7 8 15 16 24 25 27 31 65 67 71 75 79 91 95)
#PSP=(67 71 75 79 91 95)
PSP=(0)

EXT4_PSP=(0)
#BEXT4_PSP=(0)
#BEXT4_PSP=(8)
#BEXT4_PSP=(0 8 71 95)
#BEXT4_PSP=(91 219)

BEXT4_PSP=(24 152)


#FTRACE_PATH=/sys/kernel/debug/tracing

ITER=5
