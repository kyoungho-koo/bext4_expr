#!/bin/sh

# Device
# - /dev/sdb: SAMSUNG 860PRO 512GB
# - /dev/nvme0n1: SAMSUNG 970PRO 512GB

VERSION="$(uname -r| awk -F '-' '{print $2}')"

FILEBENCH_PATH="benchmark/filebench"
FILEBENCH_BIN=${FILEBENCH_PATH}/filebench
MKBIN="./mk"

#DEV=(/dev/sdm)
DEV=(/dev/nvme0n1)

MNT=/mnt

#FS=(xfs)
FS=(ext4)

#PSP=(0 1 3 7 8 15 16 24 25 27 31 65 67 71 75 79 91 95)
#PSP=(67 71 75 79 91 95)
PSP=(95)

NUM_THREADS=(40)

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
		"/dev/nvme0n1") #Optane
			OUTPUTDIR_DEV=${OUTPUTDIR}/optane
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
	esac

	echo $OUTPUTDIR_DEV
}

set_schema() {
	OUTPUTDIR_DEV_PSP=""

	# Identify storage name and set a device result name
	case $psp in
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
}


main()
{
    if [ "$VERSION" = "barrier" ]
    then
		    VERSION_PATH="./bext4"
	else
	        VERSION_PATH="./ext4"
	fi 
	
	# Create Kernel version directory
	mkdir -p ${VERSION_PATH}

	OUTPUTDIR=${VERSION_PATH}/"result_`date "+%Y%m%d"`_`date "+%H%M"`"

	# Create result root directory
	mkdir ${OUTPUTDIR}

	# Disable ASLR
	echo 0 > /proc/sys/kernel/randomize_va_space

	for dev in ${DEV[@]}
	do
		OUTPUTDIR_DEV=$(storage_info $dev)
		echo $OUTPUTDIR_DEV

		# Create directory for storage
		mkdir -p ${OUTPUTDIR_DEV}

		for psp in ${PSP[@]}
		do
			OUTPUTDIR_DEV_PSP=$(set_schema $OUTPUTDIR_DEV $psp)
			echo $OUTPUTDIR_DEV_PSP

			# Craete directory for filesystem
			mkdir -p ${OUTPUTDIR_DEV_PSP}

			COUNT=1
			while [ ${COUNT} -le ${ITER} ]
			do
				OUTPUTDIR_DEV_PSP_ITER=${OUTPUTDIR_DEV_PSP}/"ex-${COUNT}"

				# Create Directory for Iteration
				mkdir ${OUTPUTDIR_DEV_PSP_ITER}
				
				echo "# thr tx h/tx blk/tx" >> ${OUTPUTDIR_DEV_PSP_ITER}/summary;

				for num_threads in ${NUM_THREADS[@]}
				do
					echo $'\n'
					echo "==== Start experiment of ${num_threads} varmail ===="

					# Format and Mount
					echo "==== Format $dev on $MNT ===="
					${MKBIN}ext4.sh $dev $MNT
					# Initialize Page Conflict List
					cat /proc/fs/jbd2/${dev:5}-8/pcl \
						> ${OUTPUTDIR_DEV_PSP_ITER}/pcl_${num_threads}.dat;
					cat /proc/fs/jbd2/${dev:5}-8/info \
						> ${OUTPUTDIR_DEV_PSP_ITER}/info_${num_threads}.dat;
					echo "==== Fotmat complete ===="
					echo 1 > /proc/sys/kernel/lock_stat

					# Run
					echo "==== Run workload ===="
					${FILEBENCH_BIN} -f \
						${FILEBENCH_PATH}/workloads/varmail_${num_threads}.f \
						> ${OUTPUTDIR_DEV_PSP_ITER}/result_${num_threads}.dat;

					# Debug Page Conflict
					# sort by block number
					cat /proc/fs/jbd2/${dev:5}-8/pcl \
						> ${OUTPUTDIR_DEV_PSP_ITER}/pcl_${num_threads}.dat;
					cat /proc/fs/jbd2/${dev:5}-8/info \
						> ${OUTPUTDIR_DEV_PSP_ITER}/info_${num_threads}.dat;
					cat /proc/lock_stat \
						> ${OUTPUTDIR_DEV_PSP_ITER}/lock_stat_${num_threads}.dat;
					echo 0 > /proc/sys/kernel/lock_stat

					# disk anatomy
					fsstat -i raw -f ext ${dev} \
						> ${OUTPUTDIR_DEV_PSP_ITER}/disk_${num_threads};
					python3 block_identity.py \
						--disk-info ${OUTPUTDIR_DEV_PSP_ITER}/disk_${num_threads} \
						--pcl-info ${OUTPUTDIR_DEV_PSP_ITER}/pcl_${num_threads}.dat \
						--out-file ${OUTPUTDIR_DEV_PSP_ITER}/pcl_${num_threads}.dat;
					sudo sh ./summary.sh ${OUTPUTDIR_DEV_PSP_ITER}/info_${num_threads}.dat \
						${OUTPUTDIR_DEV_PSP_ITER}/result_${num_threads}.dat \
						${num_threads}>>${OUTPUTDIR_DEV_PSP_ITER}/summary;
					cat ${OUTPUTDIR_DEV_PSP_ITER}/summary | tail -1 \
						>> ${OUTPUTDIR_DEV_PSP}/summary_total
					sudo bash ./avg.sh

					echo "==== Workload complete ===="

					echo "==== End the experiment ===="
					echo $'\n'
				done
			COUNT=$(( ${COUNT}+1 ))
			done
		echo "# thr tx h/tx blk/tx" >> ${OUTPUTDIR_DEV_PSP}/summary_avg
	    awk '
			{
			c[$1]++; 
			for (i=2;i<=NF;i++) {
				s[$1"."i]+=$i};
			} 
			END {
				for (k in c) {
					printf "%s ", k; 
					for(i=2;i<NF;i++) printf "%.1f ", s[k"."i]/c[k]; 
					printf "%.1f\n", s[k"."NF]/c[k];
				}
			}' ${OUTPUTDIR_DEV_PSP}/summary_total >> ${OUTPUTDIR_DEV_PSP}/summary_avg
		done
	done

	# Enable ASLR
	echo 2 > /proc/sys/kernel/randomize_va_space
}

main
