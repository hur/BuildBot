#!/bin/bash

SCRIPTDIR=$(dirname "$0")
WORKINGDIR='/local/repository'
username=$(id -nu)
HOME=/users/$(id -un)
usergid=$(id -ng)
experimentid=$(hostname|cut -d '.' -f 2)
projectid=$usergid

sudo chown ${username}:${usergid} ${WORKINGDIR}/ -R
cd $WORKINGDIR
# Redirect output to log file
exec >> ${WORKINGDIR}/deploy.log
exec 2>&1

# make SSH shells play nice
sudo chsh -s /bin/bash $username

# Update apt lists
sudo apt-get update

sudo apt-get -y install
     git ccache automake flex lzop bison \
     gperf build-essential zip curl zlib1g-dev zlib1g-dev:i386 \
     g++-multilib python-networkx libxml2-utils bzip2 libbz2-dev \
     libbz2-1.0 libghc-bzlib-dev squashfs-tools pngcrush \
     schedtool dpkg-dev liblz4-tool make optipng maven libssl-dev \
     pwgen libswitch-perl policycoreutils minicom libxml-sax-base-perl \
	 libxml-simple-perl bc libc6-dev-i386 lib32ncurses5-dev \
     x11proto-core-dev libx11-dev lib32z-dev libgl1-mesa-dev xsltproc unzip \ 
	 repo

# get android sources 
mkdir android-kernel && cd android-kernel
repo init -u https://android.googlesource.com/kernel/manifest -b android-msm-redbull-4.19-android12L
repo sync -j$(($(nproc) + 1)) # https://unix.stackexchange.com/questions/519092/what-is-the-logic-of-using-nproc-1-in-make-command

git clone https://github.com/j0lama/kpixel5.git

/bin/bash setup.sh

/bin/bash build_pixel.sh
/bin/bash build_boot_img.sh
/bin/bash sign_image.sh

# Rudimentary build completed notification, maybe push binaries to the repo later.
cd $WORKINGDIR
git clone git@github.com:hur/kernel_builds.git
cd kernel_builds
git commit --allow-empty -m "build finished"
git push