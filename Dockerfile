FROM flowdocker/rails:0.0.78

MAINTAINER Dino Reic (dino@flow.io)

RUN apt-add-repository ppa:brightbox/ruby-ng
RUN apt-get update -qq
RUN apt-get install -y ruby2.4-dev ruby-all-dev
RUN apt-get install -y build-essential libpq-dev
RUN apt-get install -y curl
RUN apt-get install libffi-dev

RUN gem install bundler

# we add this here so it can be cached by docker and not built on every step
ADD ./Gemfile* /opt/rails/
RUN bundle install
RUN gem install rake

# add app
ADD . /opt/rails

# public/assets folder is in .dockerignore but rails needs manifest file to be in
# public/assets folder so we copy it manually
ADD public/.sprockets-manifest* public/assets/

RUN mkdir /opt/rails/log

WORKDIR /opt/rails

# java -jar /root/environment-provider.jar --service default solidus bin/start.sh production
ENTRYPOINT ["java", "-jar", "/root/environment-provider.jar", "--service", "default", "solidus", "bin/start.sh"]

HEALTHCHECK --interval=5s --timeout=5s --retries=10 CMD curl -f http://localhost:3000/_internal_/healthcheck || exit 1
