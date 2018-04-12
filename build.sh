#!/bin/sh
sudo apt-get update && sudo apt-get upgrade
sudo apt-get install live-wrapper #we need the dependencies for live wrapper, but we also need /usr/share/live-wrapper/language list to be availiable
sudo apt-get install git python-cliapp vmdebootstrap python-apt
git clone https://github.com/LinuxCNC/stretch-live-build
cd stretch-live-build
git submodule update --init --recursive
patch -p0 < ../do.sh.patch
patch -p0 < ../customise.sh.patch
patch -p0 < ../apt_udeb.py.patch
patch -p0 < ../utils.py.patch

./do.sh