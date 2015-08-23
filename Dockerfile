FROM gliderlabs/alpine:3.1

MAINTAINER Guy Balteriski <guy@codefresh.io>

RUN apk-install bash git openjdk7 ca-certificates && \
  find /usr/share/ca-certificates/mozilla/ -name *.crt -exec keytool -import -trustcacerts \
  -keystore /usr/lib/jvm/java-1.7-openjdk/jre/lib/security/cacerts -storepass changeit -noprompt \
  -file {} -alias {} \; && \
  keytool -list -keystore /usr/lib/jvm/java-1.7-openjdk/jre/lib/security/cacerts --storepass changeit

# Expose reference to JAVA_HOME
ENV JAVA_HOME /usr/lib/jvm/java-1.7-openjdk

# Adjust PATH to include all JDK related executables
ENV PATH $JAVA_HOME/bin:$PATH
