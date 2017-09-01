# FROM flowdocker/rails:0.0.78
FROM ruby:2.3.1

# Install dependencies
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs

RUN gem install bundler

ADD . /opt/rails
# ADD ./public/assets /opt/rails/public/assets

WORKDIR /opt/rails

RUN bundle install

# add to get vars from flow
COPY ./config/docker/.env /opt/rails/.env

RUN rake assets:clean
RUN rake assets:precompile

# ENTRYPOINT bundle exec puma -p 3000 -w 2 -t 0:16

# ENTRYPOINT ["java", "-jar", "/root/environment-provider.jar", "--service", "default", "solidus", "need-run-script"]

HEALTHCHECK --interval=5s --timeout=5s --retries=10 \
  CMD curl -f http://localhost:3000/_internal_/healthcheck || exit 1
