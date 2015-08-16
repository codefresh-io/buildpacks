FROM codefresh/buildpacks:nodejs

RUN apt-get install -y \
        build-essential \
        libbz2-dev \
        libsqlite3-dev \
        libreadline-dev \
        zlib1g-dev \
        libncurses5-dev \
        libssl-dev \
        libgdbm-dev && \
    apt-get clean autoclean && \
    apt-get autoremove -y && \
    rm -rf /var/lib/{apt,dpkg,cache,log}

