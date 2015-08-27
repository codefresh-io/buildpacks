############################################################
# Dockerfile to run Rails Application Containers
############################################################

FROM ubuntu:14.04

# ================================== install dependencies ==================================

ENV HOME /root
ADD ./sources.list /etc/apt/sources.list_n
RUN \
     rm /etc/apt/sources.list \
  && cp /etc/apt/sources.list_n /etc/apt/sources.list
RUN \
     mkdir -p $HOME \
  && apt-get update -qq \
  && apt-get install -y -f --no-install-recommends \
     git \
     autoconf \
     bison \
     build-essential \
     imagemagick \
     libbz2-dev \
     libcurl4-openssl-dev \
     libevent-dev \
     libffi-dev \
     libglib2.0-dev \
     libjpeg-dev \
     libmagickcore-dev \
     libmagickwand-dev \
     libmysqlclient-dev \
     libncurses-dev \
     libpq-dev \
     libreadline-dev \
     libsqlite3-dev \
     libssl-dev \
     libxml2-dev \
     libxslt-dev \
     libyaml-dev \
     libqtwebkit-dev \
     net-tools \
     qt4-qmake \
     zlib1g-dev \
     subversion \
     wget \
     curl \
     build-essential \
  && apt-get install -y -f \
     ssh \
  && apt-get clean autoclean libcomerr2 \
  && apt-get autoremove --yes \
  && rm -rf /var/lib/{apt,dpkg,cache,log}/

# ================================== Redis ==================================

RUN groupadd -r redis && useradd -r -g redis redis

# grab gosu for easy step-down from root
RUN gpg --keyserver pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4
RUN curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/1.2/gosu-$(dpkg --print-architecture)" \
	&& curl -o /usr/local/bin/gosu.asc -SL "https://github.com/tianon/gosu/releases/download/1.2/gosu-$(dpkg --print-architecture).asc" \
	&& gpg --verify /usr/local/bin/gosu.asc \
	&& rm /usr/local/bin/gosu.asc \
	&& chmod +x /usr/local/bin/gosu

ENV REDIS_VERSION 3.0.3
ENV REDIS_DOWNLOAD_URL http://download.redis.io/releases/redis-3.0.3.tar.gz
ENV REDIS_DOWNLOAD_SHA1 0e2d7707327986ae652df717059354b358b83358

# for redis-sentinel see: http://redis.io/topics/sentinel
RUN buildDeps='gcc libc6-dev make' \
	&& set -x \
	&& apt-get update && apt-get install -y $buildDeps --no-install-recommends \
	&& mkdir -p /usr/src/redis \
	&& curl -sSL "$REDIS_DOWNLOAD_URL" -o redis.tar.gz \
	&& echo "$REDIS_DOWNLOAD_SHA1 *redis.tar.gz" | sha1sum -c - \
	&& tar -xzf redis.tar.gz -C /usr/src/redis --strip-components=1 \
	&& rm redis.tar.gz \
	&& make -C /usr/src/redis \
	&& make -C /usr/src/redis install \
	&& rm -r /usr/src/redis

RUN mkdir /data && chown redis:redis /data
VOLUME /data
EXPOSE 6379

# ================================== install mongo ==================================

EXPOSE 27017
RUN \
     apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10 \
  && echo "deb http://repo.mongodb.org/apt/ubuntu "$(lsb_release -sc)"/mongodb-org/3.0 multiverse" \
     | tee /etc/apt/sources.list.d/mongodb-org-3.0.list \
  && rm -rf /var/lib/apt/lists \
  && apt-get update -qq \
  && apt-get install -y --no-install-recommends \
     mongodb-org \
  && apt-get clean autoclean \
  && apt-get autoremove --yes \
  && rm -rf /var/lib/{apt,dpkg,cache,log}/

# ================================== Install memcached ==================================

RUN \
  sudo apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 16126D3A3E5C1192 \
  && rm -rf /var/lib/apt/lists \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
    memcached \
  && apt-get clean autoclean libcomerr2 \
  && apt-get autoremove --yes \
  && rm -rf /var/lib/{apt,dpkg,cache,log}/

# ================================== Install postgresql ==================================

ENV PG_MAJOR 9.3
ENV PG_VERSION 9.3.9-1.pgdg80+1
RUN \
      apt-get update -qq \
   && apt-get install -y --no-install-recommends \
      postgresql-common \
   && sed -ri 's/#(create_main_cluster) .*$/\1 = false/' /etc/postgresql-common/createcluster.conf \
   && apt-get install -y --no-install-recommends \
      postgresql-$PG_MAJOR \
      postgresql-contrib-$PG_MAJOR \
      nodejs \
      mysql-client \
      postgresql-client \
      sqlite3 \
      locales \
   && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 \
   && apt-get clean autoclean \
   && apt-get autoremove --yes \
   && rm -rf /var/lib/{apt,dpkg,cache,log}/

ENV LANG en_US.utf8

RUN pg_createcluster $PG_MAJOR main --start \
    && /etc/init.d/postgresql start \
    && sudo -u postgres psql -c "CREATE USER root PASSWORD 'root';ALTER USER root WITH SUPERUSER;"

# ================================== Install rbenv and ruby-build ==================================

RUN \
    mkdir -p /root/.ssh \
	&& ssh-keyscan github.com >> /root/.ssh/known_hosts \
	&& git clone https://github.com/sstephenson/rbenv.git      $HOME/.rbenv \
	&& git clone https://github.com/sstephenson/ruby-build.git $HOME/.rbenv/plugins/ruby-build \
	&& $HOME/.rbenv/plugins/ruby-build/install.sh

ENV PATH $HOME/.rbenv/bin:$HOME/.rbenv/shims:$PATH

RUN \
	echo 'eval "$(rbenv init -)"' >> /etc/profile.d/rbenv.sh # or /etc/profile \
	&& echo 'eval "$(rbenv init -)"' >> /etc/profile \
	&& echo 'eval "$(rbenv init -)"' >> $HOME/.bashrc

# ================================== Install multiple versions of ruby ==================================

ADD ./versions.txt /root/versions.txt


RUN \
    apt-get update -qq \
    && apt-get install -y -f --no-install-recommends \
       build-essential \
       gcc \
       libssl-dev \
       zlib1g-dev \
    && apt-get clean autoclean libcomerr2 \
    && apt-get autoremove --yes \
    && rm -rf /var/lib/{apt,dpkg,cache,log}/ \
    && curl -fsSL https://gist.githubusercontent.com/chrosciu/daa47f611104e6929c35/raw/a5054f2b3595c6464c280dd328ee03b9563f8c3c/readline.patch | rbenv install --patch 2.1.0 \
    && cat /root/versions.txt | xargs -L 1 rbenv install \
    && cat /root/versions.txt | xargs -L 1 rbenv global \
    && echo 'gem: --no-rdoc --no-ri' >> /$HOME/.gemrc

# ======================== Install Bundler for each version of ruby ==================================

RUN \
    gem install bundler \
    && rbenv rehash \
    && bundle --version \
    && ruby --version \
    && rbenv rehash

# ================================== database.yml create && 12_factor ==================================

ADD prepare_project.rb /opt/codefresh/prepare_project.rb