echo "------Create rootfs directons start...--------"
mkdir rootfs
cd rootfs

echo "--------Create root,dev....----------"
mkdir bin boot dev etc home lib mnt proc root sbin sys tmp usr var
mkdir etc/init.d etc/rc.d etc/sysconfig
mkdir usr/sbin usr/bin usr/lib usr/modules

cat>etc/fstab<<EOF
proc    /proc   proc    defaults        0       0
sysfs   /sys    sysfs   defaults        0       0
ramfs   /dev    ramfs   defaults        0       0
EOF

cat>etc/inittab<<EOF
::sysinit:/etc/init.d/rcS
::askfirst:-/bin/ash
EOF

cat>etc/init.d/rcS<<EOF
#!/bin/ash
mount -a
mdev -s
EOF

chmod 744 etc/init.d/rcS

echo "Make node in dev/console dev/null"
echo "Please input the passwd of your PC for creating the console and null"
sudo mknod -m 666 dev/console c 5 1
sudo mknod -m 666 dev/null c 1 3
mkdir mnt/etc mnt/data mnt/temp
mkdir var/lib var/lock var/run var/tmp
chmod 1777 tmp
chmod 1777 var/tmp

echo "Creating the Linking of busybox"
ln -s bin/busybox init

echo "-------Make direction done---------"
