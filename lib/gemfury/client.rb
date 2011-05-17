require 'multi_json'
require 'faraday_middleware'

module Gemfury
  module Client
    ::Faraday::Request::JSON.adapter = ::MultiJson

  private
    def client(raw = false)
      options = {
        :url => "http://#{Const.host}",
        :ssl => { :verify => false },
        :headers => {
          'Accept' => 'application/json',
          'Content-Type' => 'application/json; charset=utf-8'
        }
      }

      Faraday.new(options) do |builder|
        builder.use Faraday::Request::JSON
        #builder.use Faraday::Response::Logger
        builder.use Faraday::Response::ParseJson
        builder.adapter :net_http
      end
    end
  end
end