require_relative 'option_interpreter/option_proxy'

module Rack
  class TrafficLogger
    class OptionInterpreter
      
      VERBS = %i[get post put patch delete head options trace]
      TYPES = %i[request_headers response_headers request_bodies response_bodies]

      def initialize(*options)
        @tests = {}
        add_rules options
      end

      class Rule
        attr_reader :arg
        def initialize(arg, filter = {})
          @arg = arg
          @filter = filter
        end
        def inspect
          "<#{@filter} #{self.class.name[/[^:]+$/]}: #{@arg}>"
        end
        def applies?(verb, code)
          return false if @filter[:verb] && verb != @filter[:verb]
          !@filter[:code] || @filter[:code] === code
        end
      end

      class OnlyVerb < Rule; end
      class OnlyCode < Rule; end
      class Include < Rule; end

      def add_rules(input, **filter)
        input = [input] unless Array === input
        verb = filter[:verb]
        code = filter[:code]
        input.each do |token|
          case token
            when *VERBS
              raise "Verb on verb (#{token} on #{verb})" if verb
              rules << OnlyVerb.new(token, filter) #[:only_verb, token, filter]
            when Fixnum, Range
              raise "Code on code (#{token} on #{code})" if code
              rules << OnlyCode.new(token, filter) #[:only_code, token, filter]
            when *TYPES
              rules << Include.new(token, filter) #[:include, token, filter]
            when :headers then add_rules [:request_headers, :response_headers], **filter
            when :bodies then add_rules [:request_bodies, :response_bodies], **filter
            when :all then add_rules [:headers, :bodies], **filter
            when Hash
              if token.keys == [:only]
                inner_hash = token.values.first
                raise 'You can only use :only => {} with a Hash' unless Hash === inner_hash
                add_rules inner_hash.keys, **filter
                add_rule_hash inner_hash, **filter
              else
                add_rule_hash token, **filter
              end
            else raise "Invalid token of type #{token.class.name} : #{token}"
          end
        end
      end

      def add_rule_hash(hash, **filter)
        hash.each { |k, v| add_rule_pair k, v, **filter }
      end

      def add_rule_pair(name, value, **filter)
        case name
          when *VERBS then add_rules value, **filter.merge(verb: name)
          when Fixnum, Range then add_rules value, **filter.merge(code: name)
          else raise "Invalid token of type #{name.class.name} : #{name}"
        end
      end

      # Test whether a given verb, status code, and log type should be logged
      # @param verb [Symbol] One of the {self::VERBS} symbols
      # @param code [Fixnum] The HTTP status code
      # @param type [Symbol|NilClass] One of the {self::TYPES} symbols, or `nil` for basic request/response details
      # @return [TrueClass|FalseClass] Whether the type should be logged
      def test(*args)
        if @tests.key? args
          @tests[args]
        else
          @tests[args] = _test *args
        end
      end

      private

      def _test(verb, code, type = nil)

        # To start, only allow if not a header/body
        type_result = type == nil

        # Exclusivity filters
        only_code = nil
        only_verb = nil

        # Loop through rules that apply to this verb and code
        rules.select { |r| r.applies? verb, code }.each do |rule|
          case rule
            when Include then type_result ||= rule.arg == type
            when OnlyVerb then only_verb ||= rule.arg == verb
            when OnlyCode then only_code ||= rule.arg === code
            else nil
          end
        end

        # Pass if the type was accepted, and exclusivity filters passed
        type_result && ![only_verb, only_code].include?(false)

      end

      def rules
        @rules ||= []
      end

    end
  end
end
