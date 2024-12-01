FROM debian:bookworm-slim

# Started from official Mopidy3 install for Debian/Ubuntu ..
# (see https://docs.mopidy.com/en/latest/installation/debian/ )
# but failed ... because apt repo was not (yet) up to date and 
# therefore switched over to PyPi installation.
# (see https://docs.mopidy.com/en/latest/installation/pypi/).

RUN set -ex \
 && apt-get update \
 && apt-get upgrade -y \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        build-essential \
        dumb-init \
        gir1.2-gst-plugins-base-1.0 \
        gir1.2-gstreamer-1.0 \
        gstreamer1.0-alsa \
#       gstreamer1.0-libav \
        gstreamer1.0-plugins-bad \
        gstreamer1.0-plugins-good \
        gstreamer1.0-plugins-ugly \
#       gstreamer1.0-pulseaudio \
        gstreamer1.0-tools \
        libcairo2-dev \
        libasound2-dev \
#       libgstreamer1.0-0 \
        libgirepository1.0-dev \
        python3 \
        python3-dev \
        python3-gst-1.0\
        python3-pip \
 && python3 -m pip install --upgrade --break-system-packages \
        mopidy \
        Mopidy-Local \
        Mopidy-Mobile \
        Mopidy-Party \
        Mopidy-Iris \
        Mopidy-MPD \
        Mopidy-ALSAMixer \
        Mopidy-MusicBox-Webclient \
 && mkdir -p /var/lib/mopidy/.config \
 && ln -s /config /var/lib/mopidy/.config/mopidy \
    # Clean-up
 && apt-get purge --auto-remove -y \
        curl \
        gcc \
        build-essential \
        python3-dev \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* ~/.cache

# Start helper script.
COPY entrypoint.sh /entrypoint.sh

# Default configuration.
COPY mopidy.conf /config/mopidy.conf

# Copy the pulse-client configuratrion.
COPY pulse-client.conf /etc/pulse/client.conf

# Allows any user to run mopidy, but runs by default as a randomly generated UID/GID.
ENV HOME=/var/lib/mopidy
RUN set -ex \
 && useradd -mUs /bin/bash mopidy \
 && usermod -G audio mopidy \
 && groups mopidy \
 && chown mopidy:audio -R $HOME /entrypoint.sh \
 && chmod go+rwx -R $HOME /entrypoint.sh

# Runs as mopidy user by default.
USER mopidy

VOLUME ["/var/lib/mopidy/local", "/var/lib/mopidy/media"]

EXPOSE 6600 6680 5555/udp

ENTRYPOINT ["/usr/bin/dumb-init", "/entrypoint.sh"]
CMD ["/usr/bin/mopidy"]
