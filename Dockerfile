# FROM flowdocker/rails:0.0.78
FROM ruby:2.3.1

# Install dependencies
RUN apt-get update -qq
RUN apt-get install -y build-essential libpq-dev nodejs cron

RUN gem install bundler

ADD . /opt/rails

WORKDIR /opt/rails

# install needed gems
RUN bundle install

# add to get vars from flow
COPY ./config/docker/.env /opt/rails/.env

# pre-compile css and js assets
RUN rake assets:clean
RUN rake assets:precompile

# install support packages
RUN apt-get install -y --no-install-recommends \
  ca-certificates apt-transport-https software-properties-common \
  curl wget unzip && \
  apt-get clean

# # install java
# RUN echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
#     echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections && \
#     add-apt-repository -y ppa:webupd8team/java && \
#     apt-get update && \
#     apt-get install -y --no-install-recommends oracle-java8-installer && \
#     /bin/rm -fr /var/cache/oracle-jdk8-installer && \
#     javac -version # test

RUN apt-get install software-properties-common && \
  echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
  echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections && \
  add-apt-repository "deb http://ppa.launchpad.net/webupd8team/java/ubuntu xenial main" && \
  apt-get update && \
  apt-get install -y --no-install-recommends oracle-java8-installer && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* && \
  rm -rf /var/cache/oracle-jdk8-installer;

# Setup JAVA_HOME, this is useful for docker commandline
#ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/
#RUN export JAVA_HOME

# # download Java Cryptography Extension
RUN cd /tmp/ && \
    curl -LO "http://download.oracle.com/otn-pub/java/jce/8/jce_policy-8.zip" -H 'Cookie: oraclelicense=accept-securebackup-cookie' && \
    unzip jce_policy-8.zip && \
    rm -f jce_policy-8.zip && \
    yes |cp -v /tmp/UnlimitedJCEPolicyJDK8/*.jar /usr/lib/jvm/java-8-oracle/jre/lib/security

# ENTRYPOINT bundle exec puma -p 3000 -w 2 -t 0:16

# ENTRYPOINT ["java", "-jar", "/root/environment-provider.jar", "--service", "default", "solidus", "need-run-script"]

# ENTRYPOINT cron -f && puma -e production

HEALTHCHECK --interval=5s --timeout=5s --retries=10 \
  CMD curl -f http://localhost:3000/_internal_/healthcheck || exit 1
