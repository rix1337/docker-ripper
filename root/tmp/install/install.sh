#!/bin/bash
#Install script for applications
#MakeMKV-RDP

#####################################
#	Install dependencies			#
#									#
#####################################

apt-get update -qq
apt-get install -qy --allow-unauthenticated build-essential pkg-config libc6-dev libssl-dev libexpat1-dev libavcodec-dev libgl1-mesa-dev qt5-default wget libfdk-aac-dev

#####################################
#	Download sources and extract    	#
#	Auto-grab latest version    			#
#####################################
VERSION=$(curl --silent 'https://forum.makemkv.com/forum/viewtopic.php?f=3&t=224' | grep MakeMKV.*.for.Linux.is | head -n 1 | sed -e 's/.*MakeMKV //g' -e 's/ .*//g')

mkdir -p /tmp/sources
wget -O /tmp/sources/makemkv-bin-$VERSION.tar.gz http://www.makemkv.com/download/makemkv-bin-$VERSION.tar.gz
wget -O /tmp/sources/makemkv-oss-$VERSION.tar.gz http://www.makemkv.com/download/makemkv-oss-$VERSION.tar.gz
wget -O /tmp/sources/ffmpeg-4.3.1.tar.bz2 https://ffmpeg.org/releases/ffmpeg-4.3.1.tar.bz2
pushd /tmp/sources/
tar xvzf /tmp/sources/makemkv-bin-$VERSION.tar.gz
tar xvzf /tmp/sources/makemkv-oss-$VERSION.tar.gz
tar xvjf /tmp/sources/ffmpeg-4.3.1.tar.bz2
popd

#####################################
#	Compile and install				#
#									#
#####################################

#FFmpeg
pushd /tmp/sources/ffmpeg-4.3.1
./configure --prefix=/tmp/ffmpeg --enable-static --disable-shared --enable-pic --disable-yasm --enable-libfdk-aac
make install
popd

# move ffmpeg bin files so ripit can access it
pushd /tmp/ffmpeg/bin
mv * /usr/bin/
popd

#Makemkv-oss
pushd /tmp/sources/makemkv-oss-$VERSION
PKG_CONFIG_PATH=/tmp/ffmpeg/lib/pkgconfig CFLAGS="-std=gnu++11" ./configure
make
make install
popd

#Makemkv-bin
pushd /tmp/sources/makemkv-bin-$VERSION
/bin/echo -e "yes" | make install
popd


#####################################
#	Remove unneeded packages		#
#									#
#####################################

apt-get remove -qy build-essential pkg-config libc6-dev libssl-dev libexpat1-dev libavcodec-dev libgl1-mesa-dev qt5-default libfdk-aac-dev
apt-get clean && rm -rf /var/lib/apt/lists/* /var/tmp/*

#####################################
#   Replace metadata for ffmpeg     #
#   so it works with Apple Music    #
#   and Quicktime                   #
#####################################
sed -i 's/author/artist/g' /usr/bin/ripit
sed -i 's/day/year/g' /usr/bin/ripit

exit
