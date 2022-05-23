#!/bin/sh
#myBuild options

#environment variables
export myBuildHome="$1"
export myBuildHelpersDir="${myBuildHome}/helpers"
export myBuildSourceDest="${myBuildHome}/sourcedest"
export myBuildExtractDest="${myBuildHome}/extractdest"
export myBuildsDir="${myBuildHome}/myBuildsBuild"

mkdir "$myBuildSourceDest"
mkdir "$myBuildExtractDest"

export J="-j12"

#this would be for binutils search paths, but i am playing my luck to see if i can go without it
#ld --verbose | grep SEARCH_DIR | tr -s ' ;' \\012
export BITS='32'

#architecture='x86' #the architecture of the target (used for building a kernel)
#export architecture

export TARGET="$(gcc -v 2>&1 | grep "^Target: " | cut -c 9-)" #the toolchain we're creating
export BUILD="$(gcc -v 2>&1 | grep "^Target: " | cut -c 9-)" #the toolchain we're compiling from, can be found by reading the "Target: *" field from "gcc -v", or "gcc -v 2>&1 | grep Target: | sed 's/.*: //" for systems with grep and sed

export SYSROOT="${myBuildHome}/rootfs" #the root dir

mkdir "$SYSROOT"

export TEMP_SYSROOT="/"

export PREFIX='/usr' #the location to install to

###	install the programs	###

export DISPLAY=:0.0
export LIBGL_ALWAYS_SOFTWARE=1

###THIS BIT ABOUT MESON IS NOT NEEDED.
##MESON START
#mkdir -p "${myBuildExtractDest}/meson"
##compile program with target compiler to test endianness
#rm "${myBuildExtractDest}/meson/testEndianness.c"
#printf "int main(){return 0;}" >> "${myBuildExtractDest}/meson/testEndianness.c"
#${TARGET}-gcc "${myBuildExtractDest}/meson/testEndianness.c" -o "${myBuildExtractDest}/meson/testEndiannessResult"

#rm "${myBuildExtractDest}/meson/mesoncross.txt"
#printf "[binaries]\n" >> "${myBuildExtractDest}/meson/mesoncross.txt"
#printf "c = '%s'\n" "$(which ${TARGET}-gcc)" >> "${myBuildExtractDest}/meson/mesoncross.txt"
#printf "cpp = '%s'\n" "$(which ${TARGET}-g++)" >> "${myBuildExtractDest}/meson/mesoncross.txt"
#printf "ar = '%s'\n" "$(which ${TARGET}-ar)" >> "${myBuildExtractDest}/meson/mesoncross.txt"
#printf "strip = '%s'\n" "$(which ${TARGET}-strip)" >> "${myBuildExtractDest}/meson/mesoncross.txt"
#printf "pkgconfig = '%s'\n" "$(which pkg-config)" >> "${myBuildExtractDest}/meson/mesoncross.txt"
#printf "[host_machine]\n" >> "${myBuildExtractDest}/meson/mesoncross.txt"
#printf "system = '%s'\n" "$(printf "%s\n" "${TARGET}" | cut -d "-" -f 2)" >> "${myBuildExtractDest}/meson/mesoncross.txt"
#printf "cpu = '%s'\n" "$(printf "%s\n" "${TARGET}" | cut -d "-" -f 1)" >> "${myBuildExtractDest}/meson/mesoncross.txt"
##write the config whether big or little endian
#if [ "$(hexdump -s 5 -n 1 -e '16/1 "%02x " "\n"' "${myBuildExtractDest}/meson/testEndiannessResult" | cut -c 1-2 )" = "01" ]; then
##little endian
#	printf "endian = 'little'\n" >> "${myBuildExtractDest}/meson/mesoncross.txt"
#elif [ "$(hexdump -s 5 -n 1 -e '16/1 "%02x " "\n"' "${myBuildExtractDest}/meson/testEndiannessResult" | cut -c 1-2 )" = "02" ]; then
##big endian
#	printf "endian = 'big'\n" >> "${myBuildExtractDest}/meson/mesoncross.txt"
#else
#printf "Uh oh! Could not determine endianness.\n"
#fi
##this will be all changed when code is merged with other myixos branch
##printf "cpu_family = '%s'\n" "$(cat "${myBuildExtractDest}/linux-deblob/theArch.config")" >> "${myBuildExtractDest}/meson/mesoncross.txt"
#if [ "$(echo "$TARGET" | cut -d - -f1)" = "i386" ] || [ "$(echo "$TARGET" | cut -d - -f1)" = "i486" ] || [ "$(echo "$TARGET" | cut -d - -f1)" = "i586" ] || [ "$(echo "$TARGET" | cut -d - -f1)" = "i686" ]; then
#	printf "cpu_family = '%s'\n" "x86" >> "${myBuildExtractDest}/meson/mesoncross.txt"
#elif [ "$(echo "$TARGET" | cut -d - -f1)" = "x86_64" ] || [ "$(echo "$TARGET" | cut -d - -f1)" = "amd64" ] || [ "$(echo "$TARGET" | cut -d - -f1)" = "ia64" ]; then
#	printf "cpu_family = '%s'\n" "x86_64" >> "${myBuildExtractDest}/meson/mesoncross.txt"
#fi

##MESON END

#we mount the stuff for apt
mount none -t proc /proc
mount none -t sysfs /sys
mkdir -p /dev/pts
mount none -t devpts /dev/pts

"${myBuildsDir}/u-boot/u-boot.myBuild" extract
"${myBuildsDir}/u-boot/u-boot.myBuild" build
"${myBuildsDir}/efilinux/efilinux.myBuild" extract
"${myBuildsDir}/efilinux/efilinux.myBuild" build
"${myBuildsDir}/linuxcnc/linuxcnc.myBuild" extract
"${myBuildsDir}/linuxcnc/linuxcnc.myBuild" build
"${myBuildsDir}/linuxcnc/linuxcnc.myBuild" install
"${myBuildsDir}/candle/candle.myBuild" extract
"${myBuildsDir}/candle/candle.myBuild" build
"${myBuildsDir}/candle/candle.myBuild" install
"${myBuildsDir}/xorriso/xorriso.myBuild" extract
"${myBuildsDir}/xorriso/xorriso.myBuild" build /
"${myBuildsDir}/xorriso/xorriso.myBuild" install /

#unmount stuff
umount /proc
umount /sys
umount /dev/pts

#"${myBuildsDir}/toxtree/toxtree.myBuild" build
#"${myBuildsDir}/tianocore/tianocore.myBuild" extract
#"${myBuildsDir}/tianocore/tianocore.myBuild" build BaseTools "shellonly"
#"${myBuildsDir}/dooble/dooble.myBuild" extract
#"${myBuildsDir}/dooble/dooble.myBuild" build
#"${myBuildsDir}/gcodesender/gcodesender.myBuild" extract
#"${myBuildsDir}/gcodesender/gcodesender.myBuild" build
#"${myBuildsDir}/gcodesender/gcodesender.myBuild" install
#"${myBuildsDir}/lasergrbl/lasergrbl.myBuild" extract
#"${myBuildsDir}/lasergrbl/lasergrbl.myBuild" build
#"${myBuildsDir}/lasergrbl/lasergrbl.myBuild" install
#"${myBuildsDir}/k3d/k3d.myBuild" extract
#"${myBuildsDir}/k3d/k3d.myBuild" build
#"${myBuildsDir}/k3d/k3d.myBuild" install
