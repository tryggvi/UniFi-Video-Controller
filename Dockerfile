FROM phusion/baseimage:0.11
MAINTAINER tryggvi@linux.is

LABEL com.example.version="3.10.13tf"
LABEL vendor1="Tryggvi Farestveit"
LABEL com.example.release-date="2021-12-18"

# Version
ENV version 3.10.13

# Set correct environment variables
ENV HOME /root
ENV DEBIAN_FRONTEND noninteractive
ENV LC_ALL C.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV PUID="99" PGID="100" UMASK="002"

# Add needed patches and scripts
ADD unifi-video.patch /unifi-video.patch
ADD unifi-video-log4j.patch /unifi-video-log4j.patch
ADD run.sh /run.sh

# Add mongodb repo, key, update and install needed packages
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 9DA31620334BD75D9DCB49F368818C72E52529D4 && \
  echo "deb [ arch=amd64,arm64 ] http://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.0 multiverse" > /etc/apt/sources.list.d/mongodb-org-4.0.list && \
  apt-get update && \
  apt-get install -y apt-utils && \
  apt-get upgrade -y -o Dpkg::Options::="--force-confold" && \
  apt-get install -y  \
    jsvc \
    jq \
    zip \
    moreutils \
    openjdk-8-jre-headless=8u162-b12-1 \
    patch \
    sudo \
    tzdata \
    moreutils \
    wget && \
  ln -s /bin/true /usr/local/bin/systemctl && \
  apt-get install -y mongodb-org-server mongodb-org-shell && \
  rm /usr/local/bin/systemctl

# Get, install and patch unifi-video
RUN wget -q -O unifi-video.deb https://dl.ubnt.com/firmwares/ufv/v${version}/unifi-video.Ubuntu18.04_amd64.v${version}.deb && \
  dpkg -i unifi-video.deb && \
  patch -lN /usr/sbin/unifi-video /unifi-video.patch && \
  patch -lN /usr/sbin/unifi-video /unifi-video-log4j.patch && \
  rm /unifi-video.deb && \
  rm /unifi-video.patch && \
  rm /unifi-video-log4j.patch && \
  chmod 755 /run.sh && \
  cd /usr/lib/unifi-video/lib &&\
  zip -q -d log4j-core-*.jar org/apache/logging/log4j/core/lookup/JndiLookup.class \

# RTMP, RTMPS & RTSP, Inbound Camera Streams & Camera Management (NVR Side), UVC-Micro Talkback (Camera Side)
# HTTP & HTTPS Web UI + API, Video over HTTP & HTTPS
EXPOSE 1935/tcp 7444/tcp 7447/tcp 6666/tcp 7442/tcp 7004/udp 7080/tcp 7443/tcp 7445/tcp 7446/tcp

# Run this potato
CMD ["/run.sh"]
