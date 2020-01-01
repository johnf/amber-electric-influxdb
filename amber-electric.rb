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

  def initialize(username, password)
    @username = username
    @password = password

    login
  end

  def price_list
    options = {
    }
    result = self.class.post('/Price/GetPriceList', options).parsed_response
    raise 'Could not fetch price list' unless result['serviceResponseType'] == 1

    result['data']
  end

  private

  def login
    options = {
      body: {
        username: @username,
        password: @password
      }.to_json
    }

    result = self.class.post('/Authentication/SignIn', options).parsed_response
    raise 'Authentication Failed' unless result['serviceResponseType'] == 1

    self.class.headers 'authorization' => result['data']['idToken']
    self.class.headers 'refreshtoken' => result['data']['refreshToken']
  end
end

# Gran data from environment
#
username = ENV['AE_USERNAME'] || abort('AE_USERNAME not set')
password = ENV['AE_PASSWORD'] || abort('AE_PASSWORD not set')
influx_hostname = ENV['INFLUXDB_HOSTNAME'] || abort('INFLUXDB_HOSTNAME not set')
influx_database = ENV['INFLUXDB_DATABASE'] || abort('INFLUXDB_DATABASE not set')

ae = AmberElectric.new(username, password)
price_list = ae.price_list

influxdb = InfluxDB::Client.new(influx_database, host: influx_hostname)

data = [
  {
    series: 'live',
    values: { price: price_list['currentPriceKWH'], renewables: price_list['currentRenewableInGrid'], colour: price_list['currentPriceColor']},
    timestamp: Time.iso8601(price_list['currentPricePeriod'].sub(/Z$/, '')).to_i
  },
]

ap data
influxdb.write_points(data)
