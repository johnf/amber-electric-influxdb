FROM ruby:2.7-alpine AS build-env

WORKDIR /usr/src/app

# Upgrade
RUN apk update --no-cache

COPY Gemfile Gemfile.lock ./
RUN bundle config --global frozen 1 \
    && bundle config --local deployment true \
    && bundle config --local path vendor/bundle \
    && bundle config --local without development \
    && bundle config --local jobs 5 \
    && bundle install \
    && rm -rf vendor/bundle/ruby/2.7.0/cache/*.gem \
    && find vendor/bundle/ruby/2.7.0/gems/ -name "*.c" -delete \
    && find vendor/bundle/ruby/2.7.0/gems/ -name "*.o" -delete

COPY amber-electric.rb .

# Main image
FROM ruby:2.7-alpine

ENV INFLUXDB_HOSTNAME influxdb
ENV INFLUXDB_DATABASE amber_electric

WORKDIR /usr/src/app

# Upgrade
RUN apk update --no-cache

COPY --from=build-env /usr/src/app /usr/src/app
COPY --from=build-env /usr/local/bundle/config /usr/local/bundle/config

CMD ["bundle", "exec", "./amber-electric.rb"]
