#!/bin/bash
#Install script for applications
#MakeMKV-RDP

add-apt-repository ppa:heyarje/makemkv-beta
apt-get update
apt-get -y install makemkv-bin makemkv-oss
apt-get -y install abcde eyed3
apt-get -y install flac lame mkcue speex vorbis-tools vorbisgain id3 id3v2
apt-get -y autoremove

#####################################
#	Remove unneeded packages		#
#									#
#####################################

apt-get remove -qy build-essential pkg-config libc6-dev libssl-dev libexpat1-dev libavcodec-dev libgl1-mesa-dev qt5-default libfdk-aac-dev
apt-get clean && rm -rf /var/lib/apt/lists/* /var/tmp/*

exit
