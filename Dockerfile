FROM flowdocker/rails:0.0.78

MAINTAINER Dino Reic (dino@flow.io)

RUN apt-add-repository ppa:brightbox/ruby-ng
RUN apt-get update -qq
RUN apt-get install -y ruby2.4-dev ruby-all-dev
RUN apt-get install -y build-essential libpq-dev nodejs cron
RUN gem install bundler
# RUN gem install rails -v 5.1

ADD . /opt/rails

WORKDIR /opt/rails

RUN bundle install

# COPY ./config/docker/.env /opt/rails/.env
# ENTRYPOINT ["java", "-jar", "/root/environment-provider.jar", "--service", "default", "solidus", "need-run-script"]

# HEALTHCHECK --interval=5s --timeout=5s --retries=10 CMD curl -f http://localhost:3000/_internal_/healthcheck || exit 1
