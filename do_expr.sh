#!/bin/sh

# Device
# - /dev/sdb: SAMSUNG 860PRO 512GB
# - /dev/nvme0n1: SAMSUNG 970PRO 512GB


#BENCHMARK="dd"
#BENCHMARK="filebench-varmail"
BENCHMARK="dbench-client"
#BENCHMARK="sysbench"


VERSION="$(uname -r| awk -F '-' '{print $2}')"



#DEV=(ramdisk /dev/nvme1n1 /dev/sdm)
DEV=(/dev/nvme1n1)
MNT=/mnt


#PSP=(0 1 3 7 8 15 16 24 25 27 31 65 67 71 75 79 91 95)
#PSP=(67 71 75 79 91 95)
PSP=(0)

EXT4_PSP=(0)
BEXT4_PSP=(0)

#NUM_THREADS=(40)

#FTRACE_PATH=/sys/kernel/debug/tracing

ITER=1


storage_info()
{
	OUTPUTDIR_DEV=""
	# Identify storage name and set a device result name
	case $1 in
		"/dev/sdk") #860PRO
			OUTPUTDIR_DEV=${OUTPUTDIR}/860pro
			;;
		"/dev/sdc") #RAID-Single Storage
			OUTPUTDIR_DEV=${OUTPUTDIR}/singleraid
			;;
		"/dev/nvme0n1") #970pro
			OUTPUTDIR_DEV=${OUTPUTDIR}/970pro
			;;
		"/dev/nvme1n1") #Optane
			OUTPUTDIR_DEV=${OUTPUTDIR}/Intel-750P
			;;
		"/dev/nvme2n1") #Optane
			OUTPUTDIR_DEV=${OUTPUTDIR}/Intel-900P
			;;
		"/dev/md5") #Software RAID 5
			OUTPUTDIR_DEV=${OUTPUTDIR}/soft-raid5
			;;
		"/dev/md0") #Software RAID 0
			OUTPUTDIR_DEV=${OUTPUTDIR}/soft-raid0
			;;
		"/dev/sdj") #Single SSD
			OUTPUTDIR_DEV=${OUTPUTDIR}/single-ssd
			;;
		"/dev/sdm") #Hardware RAID 5
			OUTPUTDIR_DEV=${OUTPUTDIR}/hard-raid5
			;;
		"/dev/sdn") #Hardware RAID 0
			OUTPUTDIR_DEV=${OUTPUTDIR}/hard-raid0
			;;
		"ramdisk") #Hardware RAID 0
			mkdir -p ./ramdisk
			mount -t ramfs ramfs ./ramdisk
			OUTPUTDIR_DEV=${OUTPUTDIR}/ramdisk
			;;
	esac

	echo $OUTPUTDIR_DEV
}

set_schema() {
	OUTPUTDIR_DEV_PSP=""

	# Identify storage name and set a device result name
	case $2 in
		"0") #default
			OUTPUTDIR_DEV_PSP=${1}/default
			;;
		"1") #psp
			OUTPUTDIR_DEV_PSP=${1}/psp
			;;
		"3") #psp-ifs
			OUTPUTDIR_DEV_PSP=${1}/psp-ifs
			;;
		"7") #psp-full
			OUTPUTDIR_DEV_PSP=${1}/psp-efs
			;;
		"8") #loop
			OUTPUTDIR_DEV_PSP=${1}/loop
			;;
		"11") #loop-psp-ifs 
			OUTPUTDIR_DEV_PSP=${1}/loop-psp-ifs
			;;	
		"15") #loop-psp-full
			OUTPUTDIR_DEV_PSP=${1}/loop-psp-efs
			;;
		"16") #count
			OUTPUTDIR_DEV_PSP=${1}/count
			;;
		"24") #count-loop
			OUTPUTDIR_DEV_PSP=${1}/count-loop
			;;
		"25") #count-loop-psp
			OUTPUTDIR_DEV_PSP=${1}/count-loop-psp
			;;
		"27") #count-loop-psp-ifs
			OUTPUTDIR_DEV_PSP=${1}/count-loop-psp-ifs
			;;
		"31") #count-loop-psp-full
			OUTPUTDIR_DEV_PSP=${1}/count-loop-psp-efs
			;;
		"47") #debug
			OUTPUTDIR_DEV_PSP=${1}/debug-loop-psp-efs
			;;
		"48") #debug
			OUTPUTDIR_DEV_PSP=${1}/debug-count
			;;
		"63") #debug
			OUTPUTDIR_DEV_PSP=${1}/debug-count-loop-psp-efs
			;;
		"65") #psp-pool 
			OUTPUTDIR_DEV_PSP=${1}/psp-pool
			;;
		"67") #psp-ifs-pool 
			OUTPUTDIR_DEV_PSP=${1}/psp-ifs-pool
			;;
		"71") #psp-efs-pool 
			OUTPUTDIR_DEV_PSP=${1}/psp-efs-pool
			;;
		"75") #loop-psp-ifs-pool 
			OUTPUTDIR_DEV_PSP=${1}/loop-psp-ifs-pool
			;;
		"79") #loop-psp-efs-pool 
			OUTPUTDIR_DEV_PSP=${1}/loop-psp-efs-pool
			;;	
		"89") #count-loop-psp-pool 
			OUTPUTDIR_DEV_PSP=${1}/count-loop-psp-pool
			;;
		"91") #count-loop-psp-ifs-pool 
			OUTPUTDIR_DEV_PSP=${1}/count-loop-psp-ifs-pool
			;;	
		"95") #count-loop-psp-efs-pool
			OUTPUTDIR_DEV_PSP=${1}/count-loop-psp-efs-pool
			;;
	esac
	./sys_psp $2
	echo $OUTPUTDIR_DEV_PSP
}


main()
{
    if [ "$VERSION" = "barrier" ]
    then
		PSP=${BEXT4_PSP[@]}
		VERSION_PATH="./bext4"
	else
		PSP=${EXT4_PSP[@]}
		VERSION_PATH="./ext4"
	fi 
	
	OUTPUTDIR=${VERSION_PATH}/"${BENCHMARK}_`date "+%Y%m%d"`_`date "+%H%M"`"

	# Disable ASLR
	echo 0 > /proc/sys/kernel/randomize_va_space

	for dev in ${DEV[@]}
	do
		OUTPUTDIR_DEV=$(storage_info $dev)

		for psp in ${PSP[@]}
		do
			OUTPUTDIR_DEV_PSP=$(set_schema $OUTPUTDIR_DEV $psp)

			sudo bash run_benchmark.sh ${BENCHMARK} ${OUTPUTDIR_DEV_PSP} ${dev}
		done
	done

	# Enable ASLR
	echo 2 > /proc/sys/kernel/randomize_va_space
}

main
