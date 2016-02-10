FROM codefresh/buildpacks:essential

# remove several traces of debian python
RUN apt-get purge -y python.*

# http://bugs.python.org/issue19846
# > At the moment, setting "LANG=C" on a Linux system *fundamentally breaks Python 3*, and that's not OK.
ENV LANG C.UTF-8

# gpg: key 18ADD4FF: public key "Benjamin Peterson <benjamin@python.org>" imported
ENV GPG_KEY C01E1CAD5EA2C4F0B8E3571504C367C218ADD4FF

ENV PYTHON_VERSION 2.7.11

# if this is called "PIP_VERSION", pip explodes with "ValueError: invalid truth value '<VERSION>'"
ENV PYTHON_PIP_VERSION 8.0.2

RUN set -ex \
	&& gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$GPG_KEY" \
	&& curl -fSL "https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tar.xz" -o python.tar.xz \
	&& curl -fSL "https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tar.xz.asc" -o python.tar.xz.asc \
	&& gpg --verify python.tar.xz.asc \
	&& mkdir -p /usr/src/python \
	&& tar -xJC /usr/src/python --strip-components=1 -f python.tar.xz \
	&& rm python.tar.xz* \
	&& rm -r ~/.gnupg \
	\
	&& cd /usr/src/python \
	&& ./configure --enable-shared --enable-unicode=ucs4 \
	&& make -j$(nproc) \
	&& make install \
	&& ldconfig \
	&& curl -fSL 'https://bootstrap.pypa.io/get-pip.py' | python2 \
	&& pip install --no-cache-dir --upgrade pip==$PYTHON_PIP_VERSION \
	&& find /usr/local \
		\( -type d -a -name test -o -name tests \) \
		-o \( -type f -a -name '*.pyc' -o -name '*.pyo' \) \
		-exec rm -rf '{}' + \
	&& rm -rf /usr/src/python

# install "virtualenv", since the vast majority of users of this image will want it
RUN pip install --no-cache-dir virtualenv

# Install Ruby 2.2.4
ENV RUBY_MAJOR=2.2 \
    RUBY_VERSION=2.2.4 \
    RUBYGEMS_VERSION=2.5.2 \
    RUBY_DOWNLOAD_SHA256=b6eff568b48e0fda76e5a36333175df049b204e91217aa32a65153cc0cdcb761

RUN echo 'install: --no-document\nupdate: --no-document' >> "$HOME/.gemrc" && \

    # some of ruby's build scripts are written in ruby
    # we purge this later to make sure our final image uses what we just built
    # libpq is needed for pg which is a popular dependency
    apt-get update \
        && apt-get install -y bison libgdbm-dev ruby autoconf libpq-dev \
        && rm -rf /var/lib/apt/lists/* \
        && mkdir -p /usr/src/ruby \
        && curl -fSL -o ruby.tar.gz "http://cache.ruby-lang.org/pub/ruby/$RUBY_MAJOR/ruby-$RUBY_VERSION.tar.gz" \
        && echo "$RUBY_DOWNLOAD_SHA256 *ruby.tar.gz" | sha256sum -c - \
        && tar -xzf ruby.tar.gz -C /usr/src/ruby --strip-components=1 \
        && rm ruby.tar.gz \
        && cd /usr/src/ruby \
        && autoconf \
        && ./configure --disable-install-doc \
        && make -j"$(nproc)" \
        && make install \
        && apt-get purge -y --auto-remove bison libgdbm-dev ruby autoconf \
        && gem update --system $RUBYGEMS_VERSION \
        && rm -r /usr/src/ruby


ENV GEM_HOME=/usr/local/bundle
ENV PATH=$GEM_HOME/bin:$PATH \
    BUNDLER_VERSION=1.10.6 \
    BUNDLE_APP_CONFIG=$GEM_HOME \
    RAILS_VERSION=4.2.5.1

RUN gem install bundler --version "$BUNDLER_VERSION" && \
    $GEM_HOME/bin/bundle config --global path "$GEM_HOME" && \
    $GEM_HOME/bin/bundle config --global bin "$GEM_HOME/bin" && \
    gem install rails --version "$RAILS_VERSION"
