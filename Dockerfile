############################################################
# Dockerfile to run Rails Application Containers
############################################################

FROM ubuntu:14.04

# ================================== install ruby ==================================
ENV HOME /root
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
  && apt-get install -y -f \
    ssh \
  && apt-get clean autoclean libcomerr2 \
  && apt-get autoremove --yes \
  && rm -rf /var/lib/{apt,dpkg,cache,log}/

# ================================== install mongo ==================================

EXPOSE 27017
RUN \
     apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10 \
  && echo "deb http://repo.mongodb.org/apt/ubuntu "$(lsb_release -sc)"/mongodb-org/3.0 multiverse" \
     | tee /etc/apt/sources.list.d/mongodb-org-3.0.list \
  && apt-get update -qq \
  && apt-get install -y --no-install-recommends \
     mongodb-org \
  && apt-get clean autoclean \
  && apt-get autoremove --yes \
  && rm -rf /var/lib/{apt,dpkg,cache,log}/

# ================================== Install memcached ==================================

RUN \
     apt-get install -y --no-install-recommends \
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
  && apt-get clean autoclean \
  && apt-get autoremove --yes \
  && rm -rf /var/lib/{apt,dpkg,cache,log}/

RUN pg_createcluster $PG_MAJOR main --start && \
        /etc/init.d/postgresql start && \
		sudo -u postgres psql -c "update pg_database set datallowconn = TRUE where datname = 'template0'; \
		update pg_database set datistemplate = FALSE where datname = 'template1';" && \
		sudo -u postgres psql -c "drop database template1;" && \
		sudo -u postgres psql -c  "create database template1 with template = template0 encoding = 'UTF8';" && \
		sudo -u postgres psql -c  "update pg_database set datistemplate = TRUE where datname = 'template1'; \
		update pg_database set datallowconn = FALSE where datname = 'template0'; \
		CREATE USER root PASSWORD 'root';ALTER USER root WITH SUPERUSER;" 		

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
    curl -fsSL https://gist.githubusercontent.com/chrosciu/daa47f611104e6929c35/raw/a5054f2b3595c6464c280dd328ee03b9563f8c3c/readline.patch | rbenv install --patch 2.1.0 \
    && cat /root/versions.txt | xargs -L 1 rbenv install \
    && cat /root/versions.txt | xargs -L 1 rbenv global \
    && echo 'gem: --no-rdoc --no-ri' >> /$HOME/.gemrc

# ================================== Install Bundler for each version of ruby ==================================
RUN \
    gem install bundler \
    && rbenv rehash \
    && bundle --version \
    && ruby --version \
    && rbenv rehash

# ================================== database.yml create && 12_factor ==================================

ADD prepare_project.rb /opt/codefresh/prepare_project.rb

