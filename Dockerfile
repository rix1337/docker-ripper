FROM phusion/baseimage:0.9.22
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
RUN apt-get update \
 && apt-get -y --allow-unauthenticated install gddrescue wget eject lame curl default-jre

# Install ripit beta that uses gnudb instead of freedb (to detect disks)
RUN wget http://ftp.br.debian.org/debian/pool/main/r/ripit/ripit_4.0.0~rc20161009-1_all.deb -O /tmp/install/ripit_4.0.0~rc20161009-1_all.deb \
 && apt install -y --allow-unauthenticated /tmp/install/ripit_4.0.0~rc20161009-1_all.deb \
 && rm /tmp/install/ripit_4.0.0~rc20161009-1_all.deb
 
# Fix libmp3-tag-perl
RUN cpan App::cpanminus \
 && cpanm MP3::Tag
 
 # Disable SSH
RUN rm -rf /etc/service/sshd /etc/my_init.d/00_regen_ssh_host_keys.sh

# Skip cache for the following install script (output is random invalidating docker cache for the next steps)
ADD "https://www.random.org/cgi-bin/randbyte?nbytes=10&format=h" skipcache
 
# MakeMKV/FFMPEG setup by github.com/tobbenb
RUN chmod +x /tmp/install/install.sh && sleep 1 && /tmp/install/install.sh && rm -r /tmp/install
