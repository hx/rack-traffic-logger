module Rack
  class TrafficLogger
    class OptionInterpreter
      class Shorthand

        ABBREVIATONS = {
            ge: :get,
            po: :post,
            pu: :put,
            pa: :patch,
            de: :delete,
            op: :options,
            he: :head,
            tr: :trace,
            h: :headers,
            b: :bodies,
            a: :all,
            ih: :request_headers,
            ib: :request_bodies,
            oh: :response_headers,
            ob: :response_bodies,
            o: :only,
            f: :false

        }.map { |k, v| [k.to_s, v.to_s] }.to_h

        def self.transform(input)
          raise ArgumentError, 'Input must be a string' unless String === input
          new(input).transform
        end

        def initialize(input)
          @input = input
        end

        def transform
          @string = @input.dup
          expand_abbreviations
          ranges
          hash_rockets_and_symbols
          wrappers
          instance_eval @string
        end

        private

        attr_accessor :string

        def expand_abbreviations
          @string.gsub!(/[_a-z]+/) { |m| ABBREVIATONS[m] || m }
        end

        def ranges
          @string.gsub!(/(\d+)-(\d+)/) { "(#{$1}..#{$2})" }
          @string.gsub!(/[1-5][\d*]\*/) { |m| '(%s..%s)' % [m.gsub('*', '0'), m.gsub('*', '9')] }
        end

        def hash_rockets_and_symbols
          @string.gsub! ':', '=>'
          @string.gsub!(/[_a-z]+/) { |m| m == 'false' ? m : ":#{m}" }
        end

        def wrappers
          @string.gsub!(/[\[{]/) { |m| "(#{m}" }
          @string.gsub!(/[\]}]/) { |m| "#{m})" }
          @string.gsub! '!', ' _false!'
          @string.gsub! '+', ' _only!'
          @string = "[#{@string}]"
        end

      end
    end
  end
end
