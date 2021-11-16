FROM phusion/baseimage:focal-1.0.0
MAINTAINER rix1337

# Set correct environment variables
ENV HOME /root
ENV DEBIAN_FRONTEND noninteractive
ENV LC_ALL C.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

# Use baseimage-docker's init system
CMD ["/sbin/my_init"]

# Configure user nobody to match unRAID's settings
RUN \
 usermod -u 99 nobody && \
 usermod -g 100 nobody && \
 usermod -d /home nobody && \
 chown -R nobody:users /home

# Move Files
COPY root/ /
RUN chmod +x /etc/my_init.d/*.sh && \
  chmod -R 777 /tmp

# Install python for web ui, eject/ffmpeg for ejecting disks
RUN apt-get update && \
    apt-get -y --allow-unauthenticated install --no-install-recommends python3 python3-pip eject abcde gddrescue eyed3 ffmpeg && \
    pip3 install docopt flask waitress && \
    apt-get -y autoremove

 # Disable SSH
RUN rm -rf /etc/service/sshd /etc/my_init.d/00_regen_ssh_host_keys.sh

# invalidate build cache on forum post change
ADD "https://forum.makemkv.com/forum/viewtopic.php?f=3&t=224" latest_post

# MakeMKV setup by https://github.com/tianon
RUN chmod +x /tmp/install/install.sh && sleep 1 && \
    /tmp/install/install.sh

# Clean up temp files
RUN rm -rf \
    	/tmp/* \
    	/var/lib/apt/lists/* \
    	/var/tmp/*
