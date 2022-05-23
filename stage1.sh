#!/bin/sh
#stage1 :- downloads a iso and extracts the root filesystem, then runs the later stages.

if [ "$1" = "" ]; then
	echo "Argv1: <arch>"
	echo "eg. \"i386\""
	exit
else
	THEARCH="$1"
fi

if [ "$(echo "$2" | cut -c 1-12)" != "linux-image-" ]; then
	echo "Argv2: the name of the kernel package for your architecture"
	echo "eg. \"linux-image-rt-686-pae\""
	exit
fi

#to extract rootfs from iso
sudo apt-get -y install squashfs-tools

#enter directory containing this script
cd $(dirname $(realpath $0))

thepwd="${PWD}"

ISONAME="devuan_chimaera_4.0.0_i386_minimal-live.iso"
wget "http://mirror.alpix.eu/devuan/devuan_chimaera/minimal-live/${ISONAME}"
mkdir "${thepwd}/mountpoint"
sudo mount -o loop "${ISONAME}" "${thepwd}/mountpoint"
cp -a "${thepwd}/mountpoint/live/filesystem.squashfs" .
sudo umount "${thepwd}/mountpoint"
sudo unsquashfs -f -no-xattrs -d "${thepwd}/mountpoint" filesystem.squashfs

#create /etc/resolv.conf for the outer rootfs
cat /etc/resolv.conf | sudo tee "${thepwd}/mountpoint/etc/resolv.conf"

THEMIRROR="http://pkgmaster.devuan.org/merged"

sudo printf "deb %s testing main contrib non-free\n" "${THEMIRROR}" | sudo tee "${thepwd}/mountpoint/etc/apt/sources.list"
sudo printf "deb-src %s testing main contrib non-free\n" "${THEMIRROR}" | sudo tee -a "${thepwd}/mountpoint/etc/apt/sources.list"

#stage 2 - run stage two in the outer rootfs
sudo mkdir "${thepwd}/mountpoint/workdir"
sudo cp -a stage2.sh "${thepwd}/mountpoint/workdir/"
chmod +x "${thepwd}/mountpoint/workdir/stage2.sh"
sudo chroot "${thepwd}/mountpoint" /workdir/stage2.sh "${THEARCH}" "http://pkgmaster.devuan.org/merged"

#copy build scripts to the outer rootfs
sudo cp -a "${thepwd}/myBuildsBuild" "${thepwd}/mountpoint/workdir"
sudo cp -a "${thepwd}/helpers" "${thepwd}/mountpoint/workdir"
sudo cp -a "${thepwd}/getEquiptmentBuild.sh" "${thepwd}/mountpoint/workdir"
sudo cp -a "${thepwd}/installEquiptmentBuild.sh" "${thepwd}/mountpoint/workdir"
sudo chmod +x "${thepwd}/mountpoint/workdir/getEquiptmentBuild.sh"
sudo chmod +x "${thepwd}/mountpoint/workdir/installEquiptmentBuild.sh"

#run build scripts in the outer rootfs
sudo chroot ${thepwd}/mountpoint /workdir/getEquiptmentBuild.sh /workdir
sudo chroot ${thepwd}/mountpoint /workdir/installEquiptmentBuild.sh /workdir

sudo mkdir -p "${thepwd}/mountpoint/workdir/rootfs/workdir"

#copy some config files to /etc/skel in the inner rootfs
sudo mkdir -p "${thepwd}/mountpoint/workdir/rootfs/etc/skel/Desktop"
sudo mkdir -p "${thepwd}/mountpoint/workdir/rootfs/etc/skel/.config"
sudo cp -a "${thepwd}/xfce4" "${thepwd}/mountpoint/workdir/rootfs/etc/skel/.config/"
sudo cp -a "${thepwd}/.xinitrc" "${thepwd}/mountpoint/workdir/rootfs/etc/skel/"
sudo chmod 700 "${thepwd}/mountpoint/workdir/rootfs/etc/skel/.xinitrc"
sudo ln -s .xinitrc "${thepwd}/mountpoint/workdir/rootfs/etc/skel/.xsession"
sudo chmod 700 "${thepwd}/mountpoint/workdir/rootfs/etc/skel/.xsession" "${thepwd}/mountpoint/workdir/rootfs/etc/skel/.xinitrc"

sudo cp -a "${thepwd}/desktopFiles" mountpoint/workdir/
find mountpoint/workdir/desktopFiles/ -name *.desktop -exec sed -i "s#/usr/bin#/usr/${TARGET}/bin#g" {} \;

#copy some .desktop files to /etc/skel in the inner rootfs
sudo cp "${thepwd}/mountpoint/workdir/desktopFiles/"*".desktop" "${thepwd}/mountpoint/workdir/rootfs/etc/skel/.local/share/applications/wine/Programs/"

#copy some config files to /root in the inner rootfs
sudo mkdir -p "${thepwd}/mountpoint/workdir/rootfs/root/Desktop"
sudo mkdir -p "${thepwd}/mountpoint/workdir/rootfs/root/.config"
sudo cp -a ${thepwd}/xfce4 "${thepwd}/mountpoint/workdir/rootfs/root/.config/"
sudo cp -a ${thepwd}/.xinitrc "${thepwd}/mountpoint/workdir/rootfs/root/"
sudo chmod 700 "${thepwd}/mountpoint/workdir/rootfs/root/.xinitrc"
sudo ln -s .xinitrc "${thepwd}/mountpoint/workdir/rootfs/root/.xsession"
sudo chmod 700 "${thepwd}/mountpoint/workdir/rootfs/root/.xsession" "${thepwd}/mountpoint/workdir/rootfs/root/.xinitrc"

#copy some .desktop files to /root in the inner rootfs
sudo cp "${thepwd}/mountpoint/workdir/desktopFiles/"*".desktop" "${thepwd}/mountpoint/workdir/rootfs/root/.local/share/applications/wine/Programs/"

#create /etc/resolv.conf for inner rootfs
cat /etc/resolv.conf | sudo tee "${thepwd}/mountpoint/workdir/rootfs/etc/resolv.conf"

###copy build scripts to inner rootfs
##sudo cp -a "${thepwd}/myBuildsHost" "${thepwd}/mountpoint/workdir/rootfs/workdir/"
##sudo cp -a "${thepwd}/helpers" "${thepwd}/mountpoint/workdir/rootfs/workdir/"
##sudo cp -a "${thepwd}/getEquiptmentHost.sh" "${thepwd}/mountpoint/workdir/rootfs/workdir/"
##sudo cp -a "${thepwd}/installEquiptmentHost.sh" "${thepwd}/mountpoint/rootfs/workdir/"
##sudo chmod +x "${thepwd}/mountpoint/workdir/rootfs/workdir/getEquiptmentHost.sh"
##sudo chmod +x "${thepwd}/mountpoint/workdir/rootfs/workdir/installEquiptmentHost.sh"

#run stage three in the inner rootfs
sudo cp "${thepwd}/stage3.sh" "${thepwd}/mountpoint/workdir/rootfs/workdir/"
sudo chmod +x "${thepwd}/mountpoint/workdir/rootfs/workdir/stage3.sh"
sudo chroot "${thepwd}/mountpoint/workdir/rootfs" /workdir/stage3.sh "${THEARCH}" "$2"

#clean up any scripts inside the inner rootfs
sudo rm -rf "${thepwd}/mountpoint/workdir/rootfs/workdir"

#stage 4 - run from the extracted iso
cd "${thepwd}"
sudo cp stage4.sh "${thepwd}/mountpoint/workdir/"
sudo cp init-overlay.sh "${thepwd}/mountpoint/workdir/"
sudo cp installToHDD.sh "${thepwd}/mountpoint/workdir/"
sudo chmod +x "${thepwd}/mountpoint/workdir/stage4.sh"
sudo chroot "${thepwd}/mountpoint" /workdir/stage4.sh "${THEARCH}"