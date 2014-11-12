require 'json'

module Rack
  class TrafficLogger
    class Formatter
      class JSON < self

        def initialize(pretty_print: false)
          formatter = pretty_print ?
              -> hash { ::JSON.pretty_generate(hash) << "\n" } :
              -> hash { ::JSON.generate(hash) << "\n" }
          define_singleton_method :format, formatter
        end

      end
    end
  end
end
