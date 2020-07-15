#/bin/bash
#set -vx
device=$1
src_dts=$device.dts
tmp_dts=$device.tmp.dts
dst_dtb=$device.dtb

cpp -nostdinc -I. -undef -x assembler-with-cpp $src_dts > $tmp_dts
./dtc -O dtb -b 0 -o $dst_dtb $tmp_dts
rm $tmp_dts
