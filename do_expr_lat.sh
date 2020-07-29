
PSP=(0 31)
#OPERATIONS=(fsync delete create)
OPERATIONS=(fsync)

echo 0 > /proc/sys/kernel/randomize_va_space

for psp in ${PSP[@]}
do
	MODE=""
	case $psp in
		"0") #default
			MODE="default"
			;;
		"31") #count-loop-psp-efs
			MODE="count_loop_psp_efs"
			;;
	esac
	./sys_psp $psp

	for operation in ${OPERATIONS[@]}
	do
		./mkext4.sh /dev/nvme0n1 /mnt

		echo ~/filebench-lat-cdf/filebench_${operation} -f ~/filebench-lat-cdf/workloads/varmail.f
		echo	bext4_${MODE}_40_${operation}.dat

		~/filebench-lat-cdf/filebench_${operation} -f ~/filebench/workloads/varmail_40.f \
			> bext4_${MODE}_40_${operation}.ret
		cat bext4_${MODE}_40_${operation}.ret | head -n -16 | tail -n +16 | sort -k 2 -n > tmp
		mv tmp bext4_${MODE}_40_${operation}.dat 
	done
done

