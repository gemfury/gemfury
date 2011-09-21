module Gemfury
  # Base Error class
  class Error < StandardError; end

  # The Gemfury gem version doesn't match the one on the server
  class InvalidGemVersion < Error; end

  # Client#user_api_key is not defined or Gemfury returns 401
  class Unauthorized < Error; end

  # Returned if something is not found
  class NotFound < Error; end
end
