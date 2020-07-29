#!/bin/bash

NTHREADS=`seq 1 40`

for nthreads in ${NTHREADS[@]}
do
	cat $1/result_${nthreads}.dat | grep "IO Sum" | awk '{print $7}'
done
