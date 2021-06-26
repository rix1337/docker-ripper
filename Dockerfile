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
RUN chmod +x /etc/my_init.d/*.sh

# Install software
RUN apt-get update && \
    apt-get -y --allow-unauthenticated install --no-install-recommends gddrescue wget eject git && \
    add-apt-repository ppa:heyarje/makemkv-beta && \
    apt-get update && \
    apt-get -y install makemkv-bin makemkv-oss ccextractor && \
    apt-get -y install abcde eyed3 && \
    apt-get -y install flac lame mkcue speex vorbis-tools vorbisgain id3 id3v2 && \
    apt-get -y autoremove

# Install python for web ui
RUN apt-get update && \
    apt-get -y --allow-unauthenticated install --no-install-recommends python3 python3-pip && \
    pip3 install docopt flask waitress && \
    apt-get -y autoremove

 # Disable SSH
RUN rm -rf /etc/service/sshd /etc/my_init.d/00_regen_ssh_host_keys.sh

# Clean up temp files
RUN rm -rf \
    	/tmp/* \
    	/var/lib/apt/lists/* \
    	/var/tmp/*
