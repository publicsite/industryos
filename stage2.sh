#!/bin/sh
#stage2 :- debootstraps a vanilla rootfs for the appropriate architecture

#enter directory containing this script
cd $(dirname $(realpath $0))

if [ "$1" = "" ]; then
	echo "Argv1: <arch>"
	echo "eg. \"i386\""
	exit
else
	THEARCH="$1"
fi

if [ "$2" = "" ]; then
	echo "Argv2: <debmirror>"
	echo "eg. \"http://pkgmaster.devuan.org/merged\""
	exit
else
	THEMIRROR="$2"
fi

export TARGET="$(gcc -v 2>&1 | grep "^Target: " | cut -c 9-)"

#we mount the stuff for apt
mount none -t proc /proc
mount none -t sysfs /sys
mkdir -p /dev/pts
mount none -t devpts /dev/pts

#fix permissions problems
chmod 666 /dev/null
chmod -Rv 700 /var/cache/apt/archives/partial/

chown -Rv devuan:devuan /var/cache/apt/archives/partial/

mkdir "${PWD}/rootfs"

apt-get update

apt-get install -m -y debootstrap

#for u-boot
apt-get -m -y install build-essential bison flex libssl-dev make

#for efilinux
apt-get -m -y install gnu-efi

#for linuxcnc
apt-get -m -y install libboost-python-dev python-is-python3 autoconf libudev-dev \
	libmodbus-dev libusb-1.0-0-dev libglib2.0-dev libgtk-3-dev libgtk2.0-dev yapps2 intltool tcl8.6-dev tk8.6-dev \
	bwidget libtk-img tclx python3-gi libeditreadline-dev python3-tk python3-opengl libglu1-mesa-dev libxmu-dev
#this will only work for libboost-python1.74 and is so that linuxcnc finds the library
ln -s /usr/lib/${TARGET}/libboost_python39.so /usr/lib/${TARGET}/libboost_python3.so

#for(k) candle(s)
apt-get -m -y install cmake qtbase5-dev libqt5serialport5-dev

#for xorriso
sudo apt-get install libburn4 libisoburn1 libisofs6

#for k3d
#apt-get -m -y install python2 libpython2-dev cmake libboost-date-time-dev libboost-program-options-dev libboost-regex-dev libboost-system-dev libboost-test-dev libglibmm-2.4-dev libsigc++-2.0-dev libgtkglext1-dev libgtkmm-2.4-dev libcairomm-1.0-dev libgl1-mesa-dev libglew-dev libftgl-dev

##for gcodesender
##apt-get -m -y install mono-devel mono-xbuild libmono-system-windows4.0-cil

##for toxtree
##apt-get -m -y install default-jdk

##for universal gcode sender
##apt-get -m -y install default-jdk

###for dooble
##apt-get -m -y install make g++ qt5-qmake qtbase5-dev libqt5charts5 libqt5charts5-dev libqt5qml5 libqt5webenginewidgets5 qtwebengine5-dev libqt5webengine5 qtwebengine5-dev-tools

###for tianocore
##apt-get -m -y install uuid-dev python3 python-is-python3 nasm

debootstrap --arch=${THEARCH} --variant=minbase --components=main,contrib,non-free --include=ifupdown testing "${PWD}/rootfs" "${THEMIRROR}"

printf "deb %s testing main contrib non-free\n" "${THEMIRROR}" > rootfs/etc/apt/sources.list
printf "deb-src %s testing main contrib non-free\n" "${THEMIRROR}" >> rootfs/etc/apt/sources.list

printf "live-hybrid-iso\n" > "rootfs/etc/hostname"
chmod 644 "rootfs/etc/hostname"
chown root:root "rootfs/etc/hostname"

printf "127.0.0.1\tlocalhost\n" > "rootfs/etc/hosts"
printf "127.0.1.1\tlive-hybrid-iso\n" >> "rootfs/etc/hosts"
printf "::1\t\tlocalhost ip6-localhost ip6-loopback\n" >> "rootfs/etc/hosts"
printf "ff02::1\t\tip6-allnodes\n" >> "rootfs/etc/hosts"
printf "ff02::2\t\tip6-allrouters\n" >> "rootfs/etc/hosts"
chmod 644 "rootfs/etc/hosts"
chown root:root "rootfs/etc/hosts"

#unmount stuff
umount /proc
umount /sys
umount /dev/pts