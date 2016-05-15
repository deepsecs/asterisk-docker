# -*- Dockerfile -*-

#FROM respoke/pjsip:latest 
FROM armv7/armhf-pjsip:2.5
MAINTAINER what <13841495@qq.com> 

ENV DEBIAN_FRONTEND=noninteractive

RUN useradd --system asterisk

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
            build-essential \
            curl \
            libcurl4-openssl-dev \
            libedit-dev \
            libgsm1-dev \
            libjansson-dev \
            libogg-dev \
            libsqlite3-dev \
            libsrtp0-dev \
            libssl-dev \
            libxml2-dev \
            libxslt1-dev \
            uuid \
            uuid-dev \
            binutils-dev \
            libpopt-dev \
            libspandsp-dev \
            libvorbis-dev \
            portaudio19-dev \
            python-pip \
            && \
    pip install j2cli && \
    apt-get purge -y --auto-remove && rm -rf /var/lib/apt/lists/*

ENV ASTERISK_VERSION=13.9.1
# COPY build-asterisk.sh /build-asterisk
# RUN /build-asterisk && rm -f /build-asterisk

RUN mkdir -p /usr/src/asterisk
WORKDIR /usr/src/asterisk

RUN curl -vsL http://downloads.asterisk.org/pub/telephony/asterisk/releases/asterisk-${ASTERISK_VERSION}.tar.gz | tar --strip-components 1 -xz

RUN ./configure
RUN make menuselect/menuselect menuselect-tree menuselect.makeopts

# MOAR SOUNDS
RUN for i in CORE-SOUNDS-EN MOH-OPSOUND EXTRA-SOUNDS-EN; do \
    for j in ULAW ALAW G722 GSM SLN16; do \
        menuselect/menuselect --enable $i-$j menuselect.makeopts; \
    done \
done

RUN make -j 4 all && make install

RUN chown -R asterisk:asterisk /var/*/asterisk && \
    chmod -R 750 /var/spool/asterisk && \
    mkdir -p /etc/asterisk/ && \
    cp /usr/src/asterisk/configs/basic-pbx/*.conf /etc/asterisk/ && \
    sed -i -E 's/^;(run)(user|group)/\1\2/' /etc/asterisk/asterisk.conf

WORKDIR /
RUN exec rm -rf /usr/src/asterisk

COPY conf/ /etc/asterisk/
COPY asterisk-docker-entrypoint.sh /

CMD ["/usr/sbin/asterisk", "-f"]
ENTRYPOINT ["/asterisk-docker-entrypoint.sh"]
