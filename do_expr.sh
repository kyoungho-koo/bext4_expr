#!/bin/sh

source parameter.sh

storage_info()
{
	OUTPUTDIR_DEV=""
	# Identify storage name and set a device result name
	case $1 in
		"/dev/sdd") #840PRO
			OUTPUTDIR_DEV=${OUTPUTDIR}/s860p
			;;
		"/dev/sda") #850PRO
			OUTPUTDIR_DEV=${OUTPUTDIR}/s870q
			;;
		"/dev/nvme0n1") #970EVO
			OUTPUTDIR_DEV=${OUTPUTDIR}/s970e
			;;
		"/dev/nvme1n1") #970PRO
			OUTPUTDIR_DEV=${OUTPUTDIR}/s970p
			;;
		"/dev/nvme2n1") #Optane
			OUTPUTDIR_DEV=${OUTPUTDIR}/i905p
			;;
	esac

	echo $OUTPUTDIR_DEV
}

set_schema() {
	OUTPUTDIR_DEV_PSP=""

	# Identify storage name and set a device result name
	case $2 in
		"0") #default
			OUTPUTDIR_DEV_PSP=${1}/def
			;;
		"1") #default
			OUTPUTDIR_DEV_PSP=${1}/debug-def
			;;
		"2") #psp
			OUTPUTDIR_DEV_PSP=${1}/c2j
			;;
		"3") #psp-ifs
			OUTPUTDIR_DEV_PSP=${1}/debug-c2j
			;;
	esac
	./sys_psp $2
	echo $OUTPUTDIR_DEV_PSP
}


main()
{
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
