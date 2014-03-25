module Gemfury
  # Base Error class
  Error = Class.new(StandardError)

  # The Gemfury gem version doesn't match the one on the server
  InvalidGemVersion = Class.new(Error)

  # Client#user_api_key is not defined or Gemfury returns 401
  Unauthorized = Class.new(Error)

  # Client is not allowed to perform this operation
  Forbidden = Class.new(Error)

  # Returned if something is not found
  NotFound = Class.new(Error)

  # Corrupt Gem File
  CorruptGemFile = Class.new(Error)

  # Version already exists
  DupeVersion = Class.new(Error)

  # TimeoutError for 503s
  TimeoutError = Class.new(Error)
end
