FROM ruby:2.3.3
MAINTAINER Dino Reic (dino@flow.io)
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs
RUN mkdir /solidus
WORKDIR /solidus
ADD . /solidus
RUN bundle install
