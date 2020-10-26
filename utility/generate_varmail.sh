#!/bin/bash

VARMAIL_PATH="benchmark/filebench/workloads"
TIME=$1
MNT_PATH="/mnt"

NTHREADS=`seq 1 80`

sed -e "s/dir=\/\char/dir=${MNT_PATH}/g" ${VARMAIL_PATH}/varmail.f

sed "s/run [^0-9]*\([0-9]\+\)/run ${TIME}/g" ${VARMAIL_PATH}/varmail.f > ${VARMAIL_PATH}/varmail.f.tmp
for nthreads in ${NTHREADS[@]}
do
	#sed "s/nthreads=16/nthreads=${nthreads}/g" varmail_${nthreads}.f > varmail_${nthreads}.f
	sed "s/nthreads=16/nthreads=${nthreads}/g" ${VARMAIL_PATH}/varmail.f.tmp > ${VARMAIL_PATH}/varmail_${nthreads}.f
done

rm ${VARMAIL_PATH}/varmail.f.tmp
