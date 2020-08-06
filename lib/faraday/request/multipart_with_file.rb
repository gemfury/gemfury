require 'faraday'

# @private
module Faraday
  # @private
  class Request::MultipartWithFile < Faraday::Middleware
    def call(env)

      # Faraday seems to expect a few IO methods to be available, but that's all:
      # https://github.com/lostisland/faraday/blob/master/lib/faraday/file_part.rb
      # :length seems to be an optional one
      file_like_objects_respond_to = ["rewind", "read", "close"].map(&:to_sym)

      if env[:body].is_a?(Hash)
        env[:body].each do |key, value|
          if file_like_objects_respond_to.all? { |m| value.respond_to? (m) }
            env[:body][key] = Faraday::UploadIO.new(value, mime_type(value), value.path)
          end
        end
      end

      @app.call(env)
    end

    private

    def mime_type(file)
      case file.path
      when /\.jpe?g/i
        'image/jpeg'
      when /\.gif$/i
        'image/gif'
      when /\.png$/i
        'image/png'
      else
        'application/octet-stream'
      end
    end
  end
end
