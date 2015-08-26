FROM codefresh/buildpacks:java7jdk
MAINTAINER Guy Balteriski <guy@codefresh.io>

# Versions

RUN curl -o scala-2.10.5.deb http://downloads.typesafe.com/scala/2.10.5/scala-2.10.5.deb && \
    apt-get -f install && \
    apt-get install -y libjansi-java && \
    dpkg -i scala-2.10.5.deb && \
    apt-get update && \
    apt-get install -y scala

ADD sbt /usr/bin/sbt
ADD sbt-launch.jar /usr/bin/sbt-launch.jar

RUN chmod u+x /usr/bin/sbt

ENV SCALA_VERSION 2.10.5
ENV SBT_VERSION 0.13.8

RUN curl https://raw.githubusercontent.com/n8han/conscript/master/setup.sh | sh && \
    /root/bin/cs n8han/giter8

# Run scala as default command
CMD ["scala"]
