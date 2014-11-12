require 'json'

module Rack
  class TrafficLogger
    class Formatter
      class JSON < self

        def format(hash)
          ::JSON.generate hash
        end

      end
    end
  end
end
