require_relative '../traffic_logger'
require 'json'

module Rack
  class TrafficLogger
    class Echo
      def call(env)
        JSON.parse env['rack.input'].tap(&:rewind).read
      end
    end
  end
end
