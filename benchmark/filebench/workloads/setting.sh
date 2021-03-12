#!/bin/bash

LIST=(1 2 4 6 8 10 20 30 40)

for i in ${LIST[@]}
do
#	sed -i "s/#flowop fsync/flowop fsync/" varmail_split16_${i}.f
	sed -i "s/nfiles=10000/nfiles=1000/" varmail_split16_${i}.f
#	sed -i "s/#flowop fsync/flowop fsync/" varmail_${i}.f
	sed -i "s/nfiles=10000/nfiles=1000/" varmail_${i}.f


done
