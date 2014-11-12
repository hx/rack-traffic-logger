require 'json'
require 'time'

module Rack
  class TrafficLogger
    class Reader

      def self.start(input, output, **options)
        new input, output, **options
      end

      def initialize(input, output, **options)
        @input = input
        @output = output
        @formatter = Formatter::Stream.new(**options)
        Signal.trap('INT') { exit 0 }
        loop { readline }
      end

      # Reads a line from input, formats it, and sends it to output
      def readline
        buffer = ''
        loop do
          begin
            buffer << @input.read_nonblock(1)
            return writeline buffer if buffer[-1] == "\n"
          rescue IO::EAGAINWaitReadable
            sleep 0.1
          rescue EOFError
            exit 0
          end
        end
      end

      def writeline(line)
        begin
          hash = JSON.parse(line)
          hash[:timestamp] = Time.parse(hash['timestamp'])
          hash[:request_log_id] = hash['request_log_id']
          hash[:event] = hash['event']
          @output << @formatter.format(hash)
        rescue
          @output << line
        end
      end

    end
  end
end
