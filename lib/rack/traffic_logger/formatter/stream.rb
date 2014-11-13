require 'time'

module Rack
  class TrafficLogger
    class Formatter
      class Stream < Formatter

        def initialize(**options)
          @simulator = StreamSimulator.new(**options)
        end

        def format(hash)
          time = Time.parse(hash['timestamp'])
          "@ #{time.strftime '%a %d %b \'%y %T.%3N'} ##{hash['request_log_id']}\n#{@simulator.format(hash)}\n\n"
        end

      end
    end
  end
end
