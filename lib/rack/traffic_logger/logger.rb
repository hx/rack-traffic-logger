require 'logger'

module Rack
  class TrafficLogger
    class Logger < ::Logger

      def initialize(*args)
        super *args
        @default_formatter = Formatter.new
      end

      class Formatter

        def call(severity, time, progname, msg)
          if severity == 'INFO'
            "#{msg}\n"
          else
            "@ #{time.strftime '%a %d %b \'%y %T'}.#{'%d' % (time.usec / 1e4)}\n#{msg}\n"
          end
        end

      end
    end
  end
end
