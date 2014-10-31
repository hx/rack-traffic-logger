require_relative '../traffic_logger'
require 'json'

module Rack
  class TrafficLogger
    class Echo
      def call(env)
        begin
          [200, {'Content-Type' => 'application/json'}, [JSON.parse(env['rack.input'].tap(&:rewind).read)]]
        rescue JSON::ParserError => error
          [
              500,
              {'Content-Type' => 'text/plain;charset=UTF-8'},
              [error.message]
          ]
        end
      end
    end
  end
end
