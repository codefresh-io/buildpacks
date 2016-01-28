FROM codefresh/buildpacks:java8-jdk

RUN /bin/bash -c "source /usr/local/sdkman/bin/sdkman-init.sh && sdk install scala && sdk install sbt"

ENTRYPOINT ["/sdkman-entrypoint.sh"]
