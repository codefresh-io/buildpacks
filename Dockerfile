FROM codefresh/buildpacks:java7jdk
MAINTAINER Guy Balteriski <guy@codefresh.io>

# Versions
ENV SCALA_VERSION 2.9.2
#ENV SBT_VERSION 0.13.8

#RUN echo "deb https://dl.bintray.com/sbt/debian /" | tee -a /etc/apt/sources.list.d/sbt.list && \
#    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 642AC823 && \
#    apt-get update && \
#    apt-get install -y scala sbt
RUN apt-get install -y scala

# Run scala as default command
CMD ["scala"]
