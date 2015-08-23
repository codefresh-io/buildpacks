FROM codefresh/buildpacks:nodejs
MAINTAINER Guy Balteriski <guy@codefresh.io>

RUN apt-get install -y \
        openjdk-7-jdk
    apt-get clean autoclean && \
    apt-get autoremove -y && \
    rm -rf /var/lib/{apt,dpkg,cache,log}

# Expose reference to JAVA_HOME
ENV JAVA_HOME /usr/lib/jvm/java-7-openjdk-amd64

# Adjust PATH to include all JDK related executables
ENV PATH $JAVA_HOME/bin:$PATH
