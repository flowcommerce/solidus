FROM flowdocker/rails:0.0.78

MAINTAINER Dino Reic (dino@flow.io)

RUN apt-get install -y ruby2.3
RUN gem install bundler

ADD . /opt/rails
WORKDIR /opt/rails

RUN bundle install

ENTRYPOINT ["java", "-jar", "/root/environment-provider.jar", "--service", "rails", "solidus", "need-run-script"]

HEALTHCHECK --interval=5s --timeout=5s --retries=10 \
  CMD curl -f http://localhost:3000/_internal_/healthcheck || exit 1
