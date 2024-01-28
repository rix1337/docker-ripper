FROM phusion/baseimage:focal-1.0.0
LABEL maintainer="rix1337"

ENV DEBIAN_FRONTEND=noninteractive \
    HOME=/root \
    LC_ALL=C.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8

# Use baseimage-docker's init system
CMD ["/sbin/my_init"]

# Configure user nobody to match unRAID's settings
RUN usermod -u 99 nobody && \
    usermod -g 100 nobody && \
    usermod -d /home nobody && \
    chown nobody:users /home -R

# Install Required packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    eject \
    sdparm \
    gddrescue \
    abcde \
    eyed3 \
    ffmpeg \
    flac \
    lame \
    mkcue \
    speex \
    vorbis-tools \
    vorbisgain \
    id3 \
    id3v2 && \
    pip3 install --no-cache-dir docopt flask waitress && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Invalidate build cache on forum post change
ADD "https://forum.makemkv.com/forum/viewtopic.php?f=3&t=224" /dev/null

# Move Files, set permissions and install makemkv
COPY root/ /
COPY manual-build/install/ /install
RUN chmod +x /etc/my_init.d/*.sh && \
    chmod -R 777 /tmp && \
    chmod 775 /install && \
    chmod +x /install/install.sh && \
    /install/install.sh && \
    rm -rf /install

# Disable SSH
RUN rm -rf /etc/service/sshd /etc/my_init.d/00_regen_ssh_host_keys.sh
