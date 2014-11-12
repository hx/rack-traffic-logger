require_relative 'formatter/stream'
require_relative 'formatter/json'

module Rack
  class TrafficLogger
    class Formatter

      def format(hash)
        raise NotImplementedError
      end

    end
  end
end
