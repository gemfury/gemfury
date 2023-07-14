# frozen_string_literal: true

require 'faraday'

# @private
module Faraday
  # @private
  class Request::MultipartWithFile < Faraday::Middleware
    def call(env)
      if env[:body].is_a?(Hash)

        # Check for IO (and IO-like objects, like Zip::InputStream) in the request,
        # which represent data to be uploaded.  Replace these with Faraday
        env[:body].each do |key, value|
          # Faraday seems to expect a few IO methods to be available, but that's all:
          # https://github.com/lostisland/faraday/blob/master/lib/faraday/file_part.rb
          # :length seems to be an optional one
          #
          # UploadIO also seems to do a duck typing check for :read, with :path optional
          # https://www.rubydoc.info/gems/multipart-post/2.0.0/UploadIO:initialize
          #
          # We attempt to make our duck typing compatible with their duck typing
          if value.respond_to?(:read) && value.respond_to?(:rewind) && value.respond_to?(:close)
            env[:body][key] = Faraday::Multipart::FilePart.new(value, mime_type(value))
          end
        end
      end

      @app.call(env)
    end

    private

    def mime_type(file)
      default = 'application/octet-stream'
      return default unless file.respond_to?(:path)

      case file.path
      when /\.jpe?g/i
        'image/jpeg'
      when /\.gif$/i
        'image/gif'
      when /\.png$/i
        'image/png'
      else
        default
      end
    end
  end
end
