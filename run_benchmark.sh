#!/bin/sh

source parameter.sh

FILEBENCH_DIR=benchmark/filebench
FILEBENCH_PERTHREADDIR_DIR=benchmark/filebench-perthreaddir
FILEBENCH_LATENCY_DIR=benchmark/filebench-latency
FILEBENCH=${FILEBENCH_DIR}/filebench
FILEBENCH_PERTHREADDIR=${FILEBENCH_PERTHREADDIR_DIR}/filebench
FILEBENCH_LATENCY=benchmark/filebench-latency/filebench
SYSBENCH=sysbench
DBENCH=dbench
MDTEST=benchmark/ior/src/mdtest
YCSB=/opt/hse-ycsb


BENCHMARK=$1
OUTPUTDIR_DEV_PSP=$2
dev=$3


lockstat_on() {
	echo 1 > /proc/sys/kernel/lock_stat
}
lockstat_off() {
	echo 0 > /proc/sys/kernel/lock_stat
	cp /proc/lock_stat $1
	echo 0 > /proc/lock_stat
}

pre_run_workload() 
{
	OUTPUTDIR_DEV_PSP_ITER=$1
	num_threads=$2

	# Format and Mount
	sudo bash mkext4.sh $dev $MNT
	echo "==== Fotmat complete ===="

	# Initialize Page Conflict List
	cat /proc/fs/jbd2/${dev:5}-8/pcl \
		> ${OUTPUTDIR_DEV_PSP_ITER}/pcl_${num_threads}.dat;
	cat /proc/fs/jbd2/${dev:5}-8/info \
		> ${OUTPUTDIR_DEV_PSP_ITER}/info_${num_threads}.dat;

	# Lock statistic
	lockstat_on

	sync && sh -c 'echo 3 > /proc/sys/vm/drop_caches'
	dmesg -c > ${OUTPUTDIR_DEV_PSP_ITER}/log_${num_threads}.txt
		
}



debug()
{

	OUTPUTDIR_DEV_PSP_ITER=$1
	num_threads=$2
	dev=$3
	# Debug Page Conflict
	# sort by block number
	cat /proc/fs/jbd2/${dev:5}-8/pcl \
		> ${OUTPUTDIR_DEV_PSP_ITER}/pcl_${num_threads}.dat;
	cat /proc/fs/jbd2/${dev:5}-8/info \
		> ${OUTPUTDIR_DEV_PSP_ITER}/info_${num_threads}.dat;

	# Lock statistic
	lockstat_off ${OUTPUTDIR_DEV_PSP_ITER}/lock_stat_${num_threads}.dat;

	# disk anatomy
	fsstat -i raw -f ext ${dev} \
		> ${OUTPUTDIR_DEV_PSP_ITER}/disk_${num_threads};
	python3 block_identity.py \
		--disk-info ${OUTPUTDIR_DEV_PSP_ITER}/disk_${num_threads} \
		--pcl-info ${OUTPUTDIR_DEV_PSP_ITER}/pcl_${num_threads}.dat \
		--out-file ${OUTPUTDIR_DEV_PSP_ITER}/pcl_${num_threads}.dat;

	dmesg -c > ${OUTPUTDIR_DEV_PSP_ITER}/log_${num_threads}.txt

	sudo bash ./avg.sh
}

save_summary()
{
	INFO=$1
	DAT=$2
	num_threads=$3
	
	TX=`grep -E "transactions" ${INFO} | awk '{print $1}'`
	HPT=`grep -E "handles per transaction" ${INFO} | awk '{print $1}'`
	BPT=`grep -E "blocks per transaction" ${INFO} | awk '{print $1}'`
	case ${BENCHMARK} in
		"filebench-varmail"|"filebench-fileserver")
		RET2=`grep -E " ops/s" $DAT | awk '{print $6}'`
		;;
		"sysbench")
		RET2=`grep -E " Requests/sec" $DAT | awk '{print $1}'`
		;;
		"dbench-client")
		RET2=`grep -E "Throughput" $DAT | awk '{print $2}'`
		;;
	esac
	echo ${num_threads} ${TX} ${HPT} ${BPT} $RET2

}

select_workload() 
{

	OUTPUTDIR_DEV_PSP_ITER=$1
	num_threads=$2

	case $BENCHMARK in
		"filebench-varmail")
			${FILEBENCH} -f \
				benchmark/filebench/workloads/varmail_${num_threads}.f \
				> ${OUTPUTDIR_DEV_PSP_ITER}/result_${num_threads}.dat;

			debug ${OUTPUTDIR_DEV_PSP_ITER} ${num_threads} ${dev}

			;;
		"filebench-varmail-split16")
			${FILEBENCH} -f \
				benchmark/filebench/workloads/varmail_split16_${num_threads}.f \
				> ${OUTPUTDIR_DEV_PSP_ITER}/result_${num_threads}.dat;

			debug ${OUTPUTDIR_DEV_PSP_ITER} ${num_threads} ${dev}

			;;
		"filebench-varmail-perthreaddir")
			echo  "${FILEBENCH_PERTHREADDIR} -f \
				${FILEBENCH_PERTHREADDIR_DIR}/workloads/varmail_${num_threads}.f \
				> ${OUTPUTDIR_DEV_PSP_ITER}/result_${num_threads}.dat;"
			${FILEBENCH_PERTHREADDIR} -f \
				${FILEBENCH_PERTHREADDIR_DIR}/workloads/varmail_${num_threads}.f \
				> ${OUTPUTDIR_DEV_PSP_ITER}/result_${num_threads}.dat;

			debug ${OUTPUTDIR_DEV_PSP_ITER} ${num_threads} ${dev}

			;;
		"filebench-varmail-latency")
			echo  "${FILEBENCH_LATENCY} -f \
				${FILEBENCH_LATENCY_DIR}/workloads/varmail_${num_threads}.f \
				> ${OUTPUTDIR_DEV_PSP_ITER}/result_${num_threads}.dat;"
			${FILEBENCH_LATENCY} -f \
				${FILEBENCH_LATENCY_DIR}/workloads/varmail_${num_threads}.f \
				> ${OUTPUTDIR_DEV_PSP_ITER}/result_${num_threads}.dat;

			debug ${OUTPUTDIR_DEV_PSP_ITER} ${num_threads} ${dev}

			;;
		"filebench-fileserver")
			;;
		"sysbench")
			filesize=128G
			CURDIR=$(pwd)
			cd $MNT

			${SYSBENCH} --test=fileio --file-total-size=${filesize} prepare
			sync

			RETFILE=${CURDIR}/${OUTPUTDIR_DEV_PSP_ITER}/result_${num_threads}.dat

			${SYSBENCH} --test=fileio --file-total-size=${filesize} \
						--file-test-mode=seqwr --file-fsync-all=on \
						--num-threads=${num_threads} --max-time=60 \
						--max-requests=0 run >> ${RETFILE}
			cd $CURDIR

			;;
		"dbench-client")
			num_process=${num_threads}
			DURATION=60
			WORKLOAD=benchmark/dbench/loadfiles/client.txt
			echo "${DBENCH} ${num_process} -t ${DURATION} -c ${WORKLOAD} -D ${MNT} --sync-dir \
				> ${OUTPUTDIR_DEV_PSP_ITER}/result_${num_process}.dat;"
			${DBENCH} ${num_process} -t ${DURATION} -c ${WORKLOAD} -D ${MNT} --sync-dir \
				> ${OUTPUTDIR_DEV_PSP_ITER}/result_${num_process}.dat;
			debug ${OUTPUTDIR_DEV_PSP_ITER} ${num_threads} ${dev}
			;;
		"rocksdb")
			;;
		"ycsb-a")
	    		MONGODWTPATH=$HOME/hse_experiment/mongo_no_hse/bin

		       # start mongo daemon
		       sudo $MONGODWTPATH/mongod --storageEngine wiredTiger --dbpath ${MNT} &
		       
		       # load data
		       $YCSB/bin/ycsb load mongodb -threads ${num_threads} -P $YCSB/workloads/workloada \
			-p recordcount=64000 \
				> ${OUTPUTDIR_DEV_PSP_ITER}/result_load_${num_threads}.dat;
		       
		       # run exp and put output to file
		       $YCSB/bin/ycsb run mongodb -threads ${num_threads} -P $YCSB/workloads/workloada \
			-p recordcount=64000 \
			-p operationcount=64000 \
				> ${OUTPUTDIR_DEV_PSP_ITER}/result_run_${num_threads}.dat;
		       
		       # drop the loaded db
		       sudo $MONGODWTPATH/mongo ycsb --eval "db.dropDatabase()"
		       sudo $MONGODWTPATH/mongod --dbpath $DBPATH --shutdown;
			sudo rm -rf ${MNT}/*
			;;
		"exim")
			;;
		"dd")
			dd if=/dev/zero of=${MNT}/test bs=4K count=2621440 oflag=dsync
			;;
		"mailbench-p")
			;;
		"mdtest")  
			num_process=${num_threads}
			num_make=300
			num_iteration=1
			num_depth=3
			num_branch=5
			write_bytes=4096

			mpirun -np ${num_process} ${MDTEST} -z ${num_depth} -b ${num_branch} \
				-I ${num_make} -i ${num_iteration} -y -w ${write_bytes} -d ${MNT} -F -C \
				> ${OUTPUTDIR_DEV_PSP_ITER}/result_${num_process}.dat
			debug ${OUTPUTDIR_DEV_PSP_ITER} ${num_threads} ${dev}
			;;
	esac

}

run_bench()
{
	COUNT=1
	while [ ${COUNT} -le ${ITER} ]
	do
		OUTPUTDIR_DEV_PSP_ITER=${OUTPUTDIR_DEV_PSP}/"ex-${COUNT}"

		# Create Directory for Iteration
		mkdir -p ${OUTPUTDIR_DEV_PSP_ITER}
		echo "directory: ${OUTPUTDIR_DEV_PSP_ITER}"
		
		echo "# thr tx h/tx blk/tx" >> ${OUTPUTDIR_DEV_PSP_ITER}/summary;

		for num_threads in ${NUM_THREADS[@]}
		do
			echo $'\n'
			echo "==== Start experiment of ${num_threads} ${BENCHMARK} ===="


			echo "==== Format $dev on $MNT ===="
			pre_run_workload ${OUTPUTDIR_DEV_PSP_ITER} ${num_threads}

			# Run
			echo "==== Run workload ===="
			select_workload ${OUTPUTDIR_DEV_PSP_ITER} ${num_threads}

			echo "==== Workload complete ===="

			save_summary ${OUTPUTDIR_DEV_PSP_ITER}/info_${num_threads}.dat \
				${OUTPUTDIR_DEV_PSP_ITER}/result_${num_threads}.dat \
				${num_threads}>>${OUTPUTDIR_DEV_PSP_ITER}/summary;
			cat ${OUTPUTDIR_DEV_PSP_ITER}/summary | tail -1 \
				>> ${OUTPUTDIR_DEV_PSP}/summary_total

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
}

run_bench
