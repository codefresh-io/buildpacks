FROM codefresh/buildpacks:nodejs
MAINTAINER Guy Balteriski <guy@codefresh.io>

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && \
    apt-get install -y software-properties-common unzip && \
    add-apt-repository -y ppa:webupd8team/java && \
    apt-get update && \
    echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | sudo debconf-set-selections && \
    apt-get install -y oracle-java8-installer && \
    apt-get clean autoclean && \
    apt-get autoremove -y && \
    rm -rf /var/lib/{apt,dpkg,cache,log}

# Expose reference to JAVA_HOME
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle

# Adjust PATH to include all JDK related executables
ENV PATH $JAVA_HOME/bin:$PATH

ENV SDKMAN_DIR /usr/local/sdkman

RUN curl -s get.sdkman.io | bash

RUN set -x \
    && echo "sdkman_auto_answer=true" > $SDKMAN_DIR/etc/config \
    && echo "sdkman_auto_selfupdate=false" >> $SDKMAN_DIR/etc/config \
    && echo "sdkman_insecure_ssl=false" >> $SDKMAN_DIR/etc/config

WORKDIR $SDKMAN_DIR

COPY sdkman-entrypoint.sh /

RUN chmod +x /sdkman-entrypoint.sh

ENTRYPOINT ["/sdkman-entrypoint.sh"]