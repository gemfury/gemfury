require 'multi_json'
require 'faraday_middleware'

module Gemfury
  module Client
    ::Faraday::Request::JSON.adapter = ::MultiJson

    def check_version
      resp = client.get('/1/status/version')

      if resp.success?
        current = Gem::Version.new(Gemfury::VERSION)
        latest = Gem::Version.new(resp.body['version'])

        unless latest.eql?(current)
          raise StandardError.new('Please update your gem')
        end
      else
        raise StandardError.new('Problem contacting GemFury')
      end
    end

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