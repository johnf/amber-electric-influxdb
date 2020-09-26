FROM ruby:2.7

ENV INFLUXDB_HOSTNAME influxdb
ENV INFLUXDB_DATABASE amber_electric

WORKDIR /usr/src/app

RUN bundle config --global frozen 1
COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

CMD ["./amber-electric.rb"]
