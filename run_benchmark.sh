ITER=1
NUM_THREADS=(40)


BENCHMARK=$1
OUTPUTDIR_DEV_PSP=$2
dev=$3



pre_run_workload() 
{
	OUTPUTDIR_DEV_PSP_ITER=$1
	num_threads=$2

	# Format and Mount
	${MKBIN}ext4.sh $dev $MNT
	echo "==== Fotmat complete ===="

	# Initialize Page Conflict List
	cat /proc/fs/jbd2/${dev:5}-8/pcl \
		> ${OUTPUTDIR_DEV_PSP_ITER}/pcl_${num_threads}.dat;
	cat /proc/fs/jbd2/${dev:5}-8/info \
		> ${OUTPUTDIR_DEV_PSP_ITER}/info_${num_threads}.dat;
	echo 1 > /proc/sys/kernel/lock_stat
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
}
run_bench()
{
	COUNT=1
	while [ ${COUNT} -le ${ITER} ]
	do
		OUTPUTDIR_DEV_PSP_ITER=${OUTPUTDIR_DEV_PSP}/"ex-${COUNT}"

		# Create Directory for Iteration
		mkdir -p ${OUTPUTDIR_DEV_PSP_ITER}
		
		echo "# thr tx h/tx blk/tx" >> ${OUTPUTDIR_DEV_PSP_ITER}/summary;

		for num_threads in ${NUM_THREADS[@]}
		do
			echo $'\n'
			echo "==== Start experiment of ${num_threads} varmail ===="


			echo "==== Format $dev on $MNT ===="
			pre_run_workload ${OUTPUTDIR_DEV_PSP_ITER} ${num_threads}

			# Run
			echo "==== Run workload ===="
			${BENCHMARK} -f \
				benchmark/filebench/workloads/varmail_${num_threads}.f \
				> ${OUTPUTDIR_DEV_PSP_ITER}/result_${num_threads}.dat;

			debug ${OUTPUTDIR_DEV_PSP_ITER} ${num_threads} ${dev}


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
}

run_bench
