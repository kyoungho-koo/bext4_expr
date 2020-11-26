#!/bin/sh

source parameter.sh

storage_info()
{
	OUTPUTDIR_DEV=""
	# Identify storage name and set a device result name
	case $1 in
		"/dev/sdk") #860PRO
			OUTPUTDIR_DEV=${OUTPUTDIR}/860pro
			;;
		"/dev/nvme0n1") #970pro
			OUTPUTDIR_DEV=${OUTPUTDIR}/970pro
			;;
		"/dev/nvme1n1") #Optane
			OUTPUTDIR_DEV=${OUTPUTDIR}/Intel-750
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
			OUTPUTDIR_DEV=${OUTPUTDIR}/sm883
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
		"9") #loop-psp-ifs 
			OUTPUTDIR_DEV_PSP=${1}/loop-psp
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
		"87") #count-loop-psp-pool 
			OUTPUTDIR_DEV_PSP=${1}/count-psp-efs-pool
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
		"152") #try-commit
			OUTPUTDIR_DEV_PSP=${1}/tc-count
			;;
		"219") #try-commit
			OUTPUTDIR_DEV_PSP=${1}/count-tc-psp-ifs-pool
			;;
		"223") #try-commit
			OUTPUTDIR_DEV_PSP=${1}/count-tc-psp-efs-pool
			;;
	esac
	./sys_psp $2
	echo $OUTPUTDIR_DEV_PSP
}


main()
{
	PSP=(0)

	if [ "$DEBUG" = "debug" ]
	then
		VERSION_PATH="${VERSION_PATH}_${DEBUG}"
		OUTPUTDIR=${VERSION_PATH}/"${DEBUG}_${BENCHMARK}_`date "+%Y%m%d"`_`date "+%H%M"`"
	else
		OUTPUTDIR=${VERSION_PATH}/"${BENCHMARK}_`date "+%Y%m%d"`_`date "+%H%M"`"
	fi 
	

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
