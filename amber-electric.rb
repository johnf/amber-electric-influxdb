#!/usr/bin/env ruby
# frozen_string_literal: true

require 'httparty'
require 'influxdb'

require 'awesome_print'

class AmberElectric
  include HTTParty
  headers 'Content-Type' => 'application/json'
  base_uri 'https://api-bff.amberelectric.com.au/api/v1.0'
  # debug_output

  attr_reader :influxdb, :once

  def initialize
    @once = ENV['ONCE']

    influx_hostname = ENV['INFLUXDB_HOSTNAME'] || abort('INFLUXDB_HOSTNAME not set')
    influx_database = ENV['INFLUXDB_DATABASE'] || abort('INFLUXDB_DATABASE not set')
    @influxdb = InfluxDB::Client.new(influx_database, host: influx_hostname)

    username = ENV['AE_USERNAME'] || abort('AE_USERNAME not set')
    password = ENV['AE_PASSWORD'] || abort('AE_PASSWORD not set')
    login(username, password)
  end

  def run
    price_list = fetch_price_list

    loop do
      data = [
        {
          series: 'live',
          values: {
            price: price_list['currentPriceKWH'],
            renewables: price_list['currentRenewableInGrid'],
            colour: price_list['currentPriceColor']
          },
          timestamp: Time.iso8601(price_list['currentPricePeriod'].sub(/Z$/, '')).to_i
        },
      ]

      influxdb.write_points(data)

      if once
        ap usage
        exit
      end

      sleep 300
    end
  end

  def fetch_price_list
    options = {
    }
    result = self.class.post('/Price/GetPriceList', options).parsed_response
    raise 'Could not fetch price list' unless result['serviceResponseType'] == 1

    result['data']
  end

  def usage
    options = {
    }
    result = self.class.post('/UsageHub/GetUsageForHub', options).parsed_response
    raise 'Could not fetch usage' unless result['serviceResponseType'] == 1

    result['data']
  end

  private

  def login(username, password)
    options = {
      body: {
        username: username,
        password: password
      }.to_json
    }

    result = self.class.post('/Authentication/SignIn', options).parsed_response
    raise 'Authentication Failed' unless result['serviceResponseType'] == 1

    self.class.headers 'authorization' => result['data']['idToken']
    self.class.headers 'refreshtoken' => result['data']['refreshToken']
  end
end

AmberElectric.new.run
# Gran data from environment
#
# usage = ae.usage
# usage['thisWeekDailyUsage'].each do |day|
# end
