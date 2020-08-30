#!/bin/sh

dev=$1
MNT=$2

if [ "${dev}" = "/mnt/ramdisk" ]
then
	echo ========ramdisk========
	umount ${dev}/ext4.image > /dev/null
	umount ${MNT} > /dev/null

	dd if=/dev/zero of=${dev}/ext4.image bs=1M count=2048
	mkfs.ext4 ${dev}/ext4.image
	mount -o loop ${dev}/ext4.image ${MNT}
else
	umount ${dev} > /dev/null
	umount ${MNT} > /dev/null

	mkfs.ext4 -F -E lazy_journal_init=0,lazy_itable_init=0 ${dev} > /dev/null
	mount -t ext4 ${dev} ${MNT} > /dev/null
	#mount -t ext4 -o nobarrier $1 $2 > /dev/null
	sync
fi

