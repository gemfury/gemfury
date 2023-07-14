# frozen_string_literal: true

RSpec.configure do |_config|
  def capture(*streams)
    streams.map!(&:to_s)
    begin
      result = StringIO.new
      streams.each { |stream| eval("$#{stream} = result", binding, __FILE__, __LINE__) }
      yield
    ensure
      streams.each { |stream| eval("$#{stream} = #{stream.upcase}", binding, __FILE__, __LINE__) }
    end
    result.string
  end
end
