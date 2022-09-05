require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  ruby '3.0.1'

  gem 'httparty'
  gem 'twilio-ruby'
  gem 'pry'
  gem 'actionview'
  gem 'dotenv'
end

require 'dotenv/load'
require 'pry'
require 'httparty'
require 'action_view'
require 'twilio-ruby'


class F2Pool
  include HTTParty
  include ActionView::Helpers::NumberHelper

  attr_accessor :hash_rate, :amount, :usd_amount, :headers, :coin_amount, :coin
  def initialize()
    @amount=0
    @headers = { "X-CMC_PRO_API_KEY" => "#{ENV['API_KEY']}" }
		@coin  = 'RVN'
		@hash_rate=0
    initialize_twilio_info
  end


  def initialize_twilio_info
    @account_sid = ENV["ACCT_SID"]
    @auth_token = ENV["AUTH_TOKEN"]
    @client = Twilio::REST::Client.new(@account_sid, @auth_token)
  end

  def run
    get_2miners_info
    get_coinmarket_cap_data
		send_sms
  end


  private

  def get_2miners_info
    response = HTTParty.get("https://rvn.2miners.com/api/accounts/RSPG5Lwx2vgs8XKbqrtSDj7XpJvbHzTwhy").parsed_response
    self.amount = response["stats"]["paid"] / 100000000
    self.hash_rate = number_to_human(response["hashrate"])
  end

  def get_coinmarket_cap_data
    data = {'convert' => 'USD', 'amount' => "#{self.amount}", 'symbol'=>"RVN"}
    coin_data = HTTParty.get(ENV["API"], query: data, headers: self.headers).parsed_response
    self.coin_amount = number_to_human(coin_data["data"][0]["quote"]["USD"]["price"],precision: 3)
  end

  def send_sms
    client = Twilio::REST::Client.new(ENV["ACCT_SID"], ENV["AUTH_TOKEN"])
    client.messages.create(from: ENV["FROM"], to: ENV["TO"], body: "Total #{self.coin}: #{self.amount}\n USD: $#{self.coin_amount}\n Hash Rate: #{self.hash_rate}")
  end
end

f2pool = F2Pool.new
f2pool.run
