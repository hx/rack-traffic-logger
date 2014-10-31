module Rack
  class TrafficLogger
    class HeaderHash < Hash

      def initialize(source = nil)
        source.each { |k, v| self[k] = v } if Hash === source
      end

      def [](key)
        super normalize_key key
      end

      def []=(key, value)
        super normalize_key(key), value
      end

      private

      def normalize_key(key)
        key.to_s.split(/[_ -]/).map { |word| word[0].upcase << word[1..-1].downcase }.join('-')
      end

    end
  end
end
