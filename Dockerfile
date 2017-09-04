# FROM flowdocker/rails:0.0.78
FROM ruby:2.3.1

# Install dependencies
RUN apt-get update -qq
RUN apt-get install -y build-essential libpq-dev nodejs cron

RUN gem install bundler

# add crontab products sync
# ADD ./config/docker/crontab /etc/cron.d/sync-products
# RUN chmod 0644 /etc/cron.d/sync-products
# RUN touch /var/log/cron.log

ADD . /opt/rails

WORKDIR /opt/rails

RUN bundle install

# add to get vars from flow
COPY ./config/docker/.env /opt/rails/.env

RUN rake assets:clean
RUN rake assets:precompile

# ENTRYPOINT bundle exec puma -p 3000 -w 2 -t 0:16

# ENTRYPOINT ["java", "-jar", "/root/environment-provider.jar", "--service", "default", "solidus", "need-run-script"]

# ENTRYPOINT cron -f && puma -e production

HEALTHCHECK --interval=5s --timeout=5s --retries=10 \
  CMD curl -f http://localhost:3000/_internal_/healthcheck || exit 1
