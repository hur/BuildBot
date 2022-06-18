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

# install repo
sudo apt-get -y install repo

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
