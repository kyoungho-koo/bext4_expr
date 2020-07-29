#!/bin/sh

# Device
# - /dev/sdb: SAMSUNG 860PRO 512GB
# - /dev/nvme0n1: SAMSUNG 970PRO 512GB

OUTPUTDIR="result_`date "+%Y%m%d"`_`date "+%H%M"`"

FILEBENCH_PATH="/home/oslab/tools/filebench_divide_dir"
#FILEBENCH_PATH="/home/oslab/tools/filebench/filebench"
FILEBENCH_BIN=${FILEBENCH_PATH}/filebench
MKBIN="./mk"

#DEV=(/dev/nvme0n1 /dev/sdl /dev/sdm)
DEV=(/dev/nvme0n1)
MNT=/mnt

#FS=(xfs)
FS=(ext4)

PSP=(1)

NUM_THREADS=(8)
#NUM_THREADS=(10)
#NUM_THREADS=(40 50 60 70 80)

main()
{
	# Create result root directory
	mkdir ${OUTPUTDIR}

	# Disable ASLR
	echo 0 > /proc/sys/kernel/randomize_va_space

	for dev in ${DEV[@]}
	do
		# Identify device name and set a device result name
		case $dev in
			"/dev/sdb") #860PRO
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
			"/dev/sdl") #Hardware RAID 5
				OUTPUTDIR_DEV=${OUTPUTDIR}/hard-raid5
				;;
			"/dev/sdm") #Hardware RAID 0
				OUTPUTDIR_DEV=${OUTPUTDIR}/hard-raid0
				;;
		esac

		# Create directory for device
		mkdir ${OUTPUTDIR_DEV}

		for psp in ${PSP[@]}
		do

			# Identify device name and set a device result name
			case $psp in
				"0") #default
					OUTPUTDIR_DEV_PSP=${OUTPUTDIR_DEV}/default
					;;
				"1") #psp
					OUTPUTDIR_DEV_PSP=${OUTPUTDIR_DEV}/psp
					;;
				"3") #psp-ifs
					OUTPUTDIR_DEV_PSP=${OUTPUTDIR_DEV}/psp-ifs
					;;
			esac
			./sys_psp $psp

			# Craete directory for filesystem
			mkdir ${OUTPUTDIR_DEV_PSP}
			echo "# thr tx h/tx blk/tx" >> ${OUTPUTDIR_DEV_PSP}/summary;

			for num_threads in ${NUM_THREADS[@]}
			do
				echo $'\n'
				echo "==== Start experiment of ${num_threads} varmail ===="

				# Format and Mount
				echo "==== Format $dev on $MNT ===="
				${MKBIN}ext4.sh $dev $MNT
				# Initialize Page Conflict List
				cat /proc/fs/jbd2/${dev:5}-8/pcl \
					> ${OUTPUTDIR_DEV_PSP}/pcl_${num_threads}.dat;
				cat /proc/fs/jbd2/${dev:5}-8/info \
					> ${OUTPUTDIR_DEV_PSP}/info_${num_threads}.dat;
				echo "==== Fotmat complete ===="

				# Run
				echo "==== Run workload ===="
				${FILEBENCH_BIN} -f \
					${FILEBENCH_PATH}/workloads/varmail_divide_dir_${num_threads}.f \
					> ${OUTPUTDIR_DEV_PSP}/result_${num_threads}.dat;

				# Debug Page Conflict
				# sort by block number
				cat /proc/fs/jbd2/${dev:5}-8/pcl \
					> ${OUTPUTDIR_DEV_PSP}/pcl_${num_threads}.dat;
				cat /proc/fs/jbd2/${dev:5}-8/info \
					> ${OUTPUTDIR_DEV_PSP}/info_${num_threads}.dat;

				# disk anatomy
				fsstat -i raw -f ext4 ${dev} \
					> ${OUTPUTDIR_DEV_PSP}/disk_${num_threads};

				python3 block_identity.py \
					--disk-info  ${OUTPUTDIR_DEV_PSP}/disk_${num_threads} \
					--pcl-info ${OUTPUTDIR_DEV_PSP}/pcl_${num_threads}.dat \
					--out-file ${OUTPUTDIR_DEV_PSP}/pcl_${num_threads}.dat;

				sudo sh ./summary.sh ${OUTPUTDIR_DEV_PSP}/info_${num_threads}.dat ${OUTPUTDIR_DEV_PSP}/result_${num_threads}.dat ${num_threads}\
					>>${OUTPUTDIR_DEV_PSP}/summary;

				echo "==== Workload complete ===="

				echo "==== End the experiment ===="
				echo $'\n'
			done
		done
	done

	# Enable ASLR
	echo 2 > /proc/sys/kernel/randomize_va_space
}

main
