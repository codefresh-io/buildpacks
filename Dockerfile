FROM codefresh/buildpacks:essential

# Add Python pyenv and set default to 3.4.2
RUN curl -o- https://raw.githubusercontent.com/yyuu/pyenv-installer/master/bin/pyenv-installer | bash && \

    echo 'export PATH="$HOME/.pyenv/bin:$PATH"' >> /root/.bashrc && \
    echo 'eval "$(pyenv init -)"' >> /root/.bashrc && \
    echo 'eval "$(pyenv virtualenv-init -)"' >> /root/.bashrc && \

    bash -ilc 'pyenv install 3.4.2 && pyenv global 3.4.2'

# Install Ruby 2.2.2
ENV RUBY_MAJOR=2.2 \
    RUBY_VERSION=2.2.2 \
    RUBYGEMS_VERSION=2.4.8 \
    RUBY_DOWNLOAD_SHA256=5ffc0f317e429e6b29d4a98ac521c3ce65481bfd22a8cf845fa02a7b113d9b44

RUN echo 'install: --no-document\nupdate: --no-document' >> "$HOME/.gemrc" && \

    # some of ruby's build scripts are written in ruby
    # we purge this later to make sure our final image uses what we just built
    apt-get update \
        && apt-get install -y bison libgdbm-dev ruby autoconf \
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


ENV GEM_HOME=/usr/local/bundle \
    PATH=$GEM_HOME/bin:$PATH \

    BUNDLER_VERSION=1.10.6 \
    BUNDLE_APP_CONFIG=$GEM_HOME \

    RAILS_VERSION=4.2.3

RUN gem install bundler --version "$BUNDLER_VERSION" && \
    $GEM_HOME/bin/bundle config --global path "$GEM_HOME" && \
    $GEM_HOME/bin/bundle config --global bin "$GEM_HOME/bin" && \
    gem install rails --version "$RAILS_VERSION"

