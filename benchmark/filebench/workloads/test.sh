#!/bin/bash

LIST=(1 2 4 6 8 10 20 30 40)

for i in ${LIST[@]}
do
	cat varmail_${i}.f | grep "nfiles="
	cat varmail_${i}.f | grep fsync

	cat varmail_split16_${i}.f | grep "nfiles="
	cat varmail_split16_${i}.f | grep fsync

done
