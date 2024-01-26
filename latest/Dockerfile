FROM phusion/baseimage:focal-1.0.0
LABEL maintainer="rix1337"

ENV DEBIAN_FRONTEND=noninteractive \
    LC_ALL=C.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    HOME=/root

# Disable SSH
RUN rm -rf /etc/service/sshd /etc/my_init.d/00_regen_ssh_host_keys.sh

# Use baseimage-docker's init system
CMD ["/sbin/my_init"]

# Install software
RUN add-apt-repository -y ppa:heyarje/makemkv-beta && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
      abcde \
      ccextractor \
      eject \
      eyed3 \
      flac \
      gddrescue \
      git \
      id3 \
      id3v2 \
      lame \
      makemkv-bin \
      makemkv-oss \
      mkcue \
      python3 \
      python3-pip \
      sdparm \
      speex \
      vorbis-tools \
      vorbisgain \
      wget && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install python packages for web ui
RUN pip3 install --no-cache-dir \
    docopt \
    flask \
    waitress

# Invalidate build cache on new releases of MakeMKV
ADD "https://launchpad.net/~heyarje/+archive/ubuntu/makemkv-beta/+builds?build_text=makemkv-bin&build_state=built" /dev/null

# Move Files and set permissions
COPY root/ /
RUN chmod +x /etc/my_init.d/*.sh