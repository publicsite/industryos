#!/bin/sh

OLD_UMASK="$(umask)"
umask 0022

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

###	get the programs	###

"${myBuildsDir}/u-boot/u-boot.myBuild" get
"${myBuildsDir}/efilinux/efilinux.myBuild" get
"${myBuildsDir}/linuxcnc/linuxcnc.myBuild" get
"${myBuildsDir}/candle/candle.myBuild" get
"${myBuildsDir}/xorriso/xorriso.myBuild" get

#"${myBuildsDir}/toxtree/toxtree.myBuild" get stage1
#"${myBuildsDir}/toxtree/toxtree.myBuild" extract
#"${myBuildsDir}/toxtree/toxtree.myBuild" get stage2
#"${myBuildsDir}/universal-g-code-sender/universal-g-code-sender.myBuild" get stage1
#"${myBuildsDir}/universal-g-code-sender/universal-g-code-sender.myBuild" extract
#"${myBuildsDir}/gcodesender/gcodesender.myBuild" get
#"${myBuildsDir}/lasergrbl/lasergrbl.myBuild" get
#"${myBuildsDir}/k3d/k3d.myBuild" get
#"${myBuildsDir}/universal-g-code-sender/universal-g-code-sender.myBuild" get stage2

umask "${OLD_UMASK}"
