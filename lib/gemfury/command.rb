require 'thor'
require 'launchy'
require 'highline'

module Gemfury
  class Command < Thor
    desc "version" ,"Check whether the gem is up-to-date"
    def version
      client.check_version
    end

    desc "push GEM" ,"upload a new version of a gem"
    def push(*gems)
      if gems.empty?
        shell.say "Problem: No gems specified", :red
        help(:push)
        return
      end

      # Collect registration info
      term = HighLine.new
      term.say(Const.welcome)
      email = term.ask("Email: ") do |q|
        q.responses[:not_valid] = Const.email_error
        q.validate = Const.email_regex
      end

      # Send the registration request
      conn = client.send(:connection) # From Gemfury::Client
      resp = conn.post('/invites.json', :invite => { :email => email })

      # Handle the registration
      if resp.success?
        body = resp.body
        term.say "Thanks! Gemfury is almost ready. Please stay tuned."
        Launchy.open("http://#{Const.host}/invites/#{body['slug']}")
      else
        term.say "Oops! Something went wrong. Please try again", :red
      end
    end

  private
    def client
      Gemfury::Client.new
    end
  end
end