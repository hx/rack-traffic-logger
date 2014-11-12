module Rack
  class TrafficLogger
    class Formatter
      class Stream < self

        def initialize(**options)
          @simulator = StreamSimulator.new(**options)
        end

        def format(hash)
          time = hash[:timestamp]
          id = hash[:request_log_id]
          "@ #{time.strftime '%a %d %b \'%y %T'}.#{'%d' % (time.usec / 1e4)} ##{id}\n" << @simulator.format(hash)
        end

      end
    end
  end
end
