FROM debian:wheezy


RUN echo "deb http://http.debian.net/debian wheezy-backports main" >/etc/apt/sources.list.d/wheezy-backports.list && \
    apt-get update -qq && \
    apt-get -t wheezy-backports install -y -qq git && \
    apt-get install -y \
        ssh \
        sshpass \
        curl && \

    curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.25.4/install.sh | bash && \

    echo 'export NVM_DIR="/root/.nvm"' >> ~/.bashrc && \
    echo '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"' >> ~/.bashrc && \

    bash -ilc 'nvm install 0.12.7 \
            && nvm alias 0.12.7 stable \
            && nvm install iojs \
            && nvm alias iojs stable \
            && nvm alias default 0.12.7' && \

    bash -ilc 'npm install -g bower grunt-cli gulp && npm cache clean' && \

    apt-get clean autoclean && \
    apt-get autoremove -y && \
    rm -rf /var/lib/{apt,dpkg,cache,log}/


