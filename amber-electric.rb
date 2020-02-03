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
    loop do
      data = []

      price_list = fetch_price_list
      usage = fetch_usage

      data << generate_price_list(price_list)

      (usage['lastWeekDailyUsage'] + usage['thisWeekDailyUsage']).each do |day|
        data << generate_usage(day)
      end

      if once
        puts 'Price List'
        ap price_list
        puts

        puts 'Usage'
        ap usage
        puts

        puts 'Data'
        ap data
        puts
        exit
      end

      influxdb.write_points(data)

      sleep 300
    end
  end

  def generate_price_list(price_list)
    {
      series: 'live',
      values: {
        price: price_list['currentPriceKWH'],
        renewables: price_list['currentRenewableInGrid'],
        colour: price_list['currentPriceColor']
      },
      timestamp: timestamp(price_list['currentPricePeriod']),
    }
  end

  def generate_usage(usage)
    case usage['meterSuffix']
    when 'B1'
      type = 'solar'
      multiplier = -1
    when 'E1'
      type = 'grid'
      multiplier = 1
    else
      raise 'Unknown meter'
    end
    {
      series: 'usage',
      values: {
        type: usage['usageType'],
        cost: usage['usageCost'],
        kWH: usage['usageKWH'] * multiplier,
        # average_price: usage['usageAveragePrice'],
        price_spikes: usage['usagePriceSpikes'],
        daily_fixed_cost: usage['dailyFixedCost'],
      },
      tags: { type: type },
      timestamp: timestamp(usage['date']),
    }
  end


  def fetch_price_list
    options = {
    }
    result = self.class.post('/Price/GetPriceList', options).parsed_response
    raise 'Could not fetch price list' unless result['serviceResponseType'] == 1

    result['data']
  end

  def fetch_usage
    result = self.class.post('/UsageHub/GetUsageForHub').parsed_response
    raise 'Could not fetch usage' unless result['serviceResponseType'] == 1

    result['data']
  end

  def timestamp(stamp)
    localtime = stamp.sub(/Z$/, '')

    Time.iso8601(localtime).to_i
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
