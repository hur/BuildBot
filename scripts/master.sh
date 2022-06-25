#!/bin/bash

set -eux

if [ "$#" -ne 1 ]; then
    echo "Missing GitHub tokens" | tee /local/repository/deploy.log
    exit 1
fi

SCRIPTDIR=$(dirname "$0")
WORKINGDIR='/buildbot'
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

sudo apt-get -y install git ccache automake flex lzop bison \
    gperf build-essential zip curl zlib1g-dev zlib1g-dev:i386 \
    g++-multilib python-networkx libxml2-utils bzip2 libbz2-dev \
    libbz2-1.0 libghc-bzlib-dev squashfs-tools pngcrush \
    schedtool dpkg-dev liblz4-tool make optipng maven libssl-dev \
    pwgen libswitch-perl policycoreutils minicom libxml-sax-base-perl \
    libxml-simple-perl bc libc6-dev-i386 lib32ncurses5-dev \
    x11proto-core-dev libx11-dev lib32z-dev libgl1-mesa-dev xsltproc unzip

# install repo
mkdir ~/bin
export REPO=$(mktemp /tmp/repo.XXXXXXXXX)
curl -o ${REPO} https://storage.googleapis.com/git-repo-downloads/repo
gpg --keyserver keys.openpgp.org --recv-key 8BB9AD793E8E6153AF0F9A4416530D5E920F5C65
curl -s https://storage.googleapis.com/git-repo-downloads/repo.asc | gpg --verify - ${REPO} && install -m 755 ${REPO} ~/bin/repo

export PATH=$PATH:~/bin/repo

# for repo non-interactive mode & build notifications
git config --global user.name "BuildBot"
git config --global user.email "buildbot@atteniemi.com"

# get android sources 
mkdir android-kernel && cd android-kernel
~/bin/repo init -u https://android.googlesource.com/kernel/manifest -b android-msm-redbull-4.19-android12L < /dev/null
~/bin/repo sync -j$(($(nproc) + 1)) 

# get compilation scripts for pixel 5 & compile
git clone https://hur:$1@github.com/hur/kpixel5.git && cd kpixel5

/bin/bash setup.sh && cd ..

/bin/bash build_pixel.sh
/bin/bash build_boot_img.sh
/bin/bash sign_image.sh

# Rudimentary build completed notification, maybe push binaries to the repo later.
cd $WORKINGDIR
git clone https://hur:$1@github.com/hur/kernel_builds.git
cd kernel_builds

git commit --allow-empty -m "build finished"
git push
