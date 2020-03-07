FROM debian:buster-slim

# Started from official Mopidy3 install for Debian/Ubuntu ..
# (see https://docs.mopidy.com/en/latest/installation/debian/ )
# but failed ... because apt repo was not (yet) up to date and 
# therefore switched over to PyPi installation.
# (see https://docs.mopidy.com/en/latest/installation/pypi/).
#
#
# Hint: Mopidy-Iris # Fails with at startup with 
#       'Failed to load extension iris: No module named 'handlers' [7:MainThread:mopidy.ext]'
#       therfore it was not installed.

RUN set -ex \
 && apt-get update \
 && apt-get upgrade -y \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        wget \
        gnupg2 \
        dumb-init \
        python3 \
        python3-pip \
        python3-dev \
        python3-crypto \
        python3-gst-1.0 \
        build-essential \
        libgstreamer1.0-0 \
        gstreamer1.0-plugins-good \
        gstreamer1.0-plugins-ugly \
        gstreamer1.0-plugins-bad \
        gstreamer1.0-tools \
        gstreamer1.0-alsa \
 && wget -q -O - https://apt.mopidy.com/mopidy.gpg | apt-key add - \
 && wget -q -O /etc/apt/sources.list.d/mopidy.list https://apt.mopidy.com/buster.list \
 && apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y libasound2-dev libspotify-dev \
 && python3 -m pip install --upgrade mopidy \
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
        wget \
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
