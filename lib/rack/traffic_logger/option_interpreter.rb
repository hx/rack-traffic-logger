require_relative 'option_interpreter/option_proxy'

module Rack
  class TrafficLogger
    class OptionInterpreter

      DEFAULTS = {
          requests: true,
          responses: true,
          request_headers: false,
          request_bodies: false,
          response_headers: false,
          response_bodies: false
      }

      SILENT = {} # Hash.new { false }

      VERBS = %i[get post put patch delete head options trace]

      class OptionSet < Hash
        attr_reader :defaults

        def initialize(defaults = nil)
          @defaults = defaults || DEFAULTS.dup
          default_set = new_child
          super() { @only_isolated || default_set }
        end

        def isolate(code)
          self[code] = new_child unless key? code
        end

        def only_isolated!
          @only_isolated = new_child(SILENT)
        end

        def new_child(defaults = nil)
          self.class.child_class.new defaults || @defaults
        end
      end

      class GlobalOptionSet < OptionSet
        def self.child_class
          VerbOptionSet
        end
      end

      class VerbOptionSet < OptionSet
        def self.child_class
          CodeOptionSet
        end
      end

      class CodeOptionSet < Hash
        def initialize(defaults)
          super() { |_, k| defaults[k] }
        end
      end

      def initialize(*options)
        @proxies = {}
        @options = GlobalOptionSet.new
        interpret options
      end

      def for(*args)
        @proxies[args.join('|')] ||= OptionProxy.new(self, args)
      end

      DEFAULTS.each_key do |attr|
        shortcut = :"#{attr}?"
        define_method shortcut do |*args|
          self.for(*args).__send__ shortcut
        end
      end

      private

      def interpret(options, verb: nil, code: nil)
        options.each do |option|
          case option
            when *VERBS
              raise "Tried to nest verb rules (#{option} on #{verb})" if verb
              if code

              else
                @options.isolate option
                @explicit_verbs = true
              end
          end
        end
        if @explicit_verbs
          (VERBS - @options.keys).each do |verb|
            @options.isolate verb
            DEFAULTS.each_key { |option| @options[verb][nil][option] = false }
          end
        end
      end

      # def set_options(options, verb: nil, code: nil)
      #
      #
      #   use_verbs! if verb
      #   use_codes! if code
      #   options = normalize_options(options)
      #   if verb
      #     set_options_for_verb options, verb, code: code
      #   elsif code
      #     @by_verb.each_key { |v| set_options_for_verb options, v, code: code }
      #   else
      #     @defaults.merge! options
      #   end
      # end
      #
      # def set_options_for_verb(options, verb, code: nil)
      #   verb_options = @by_verb[verb]
      #   if @use_codes
      #     if code
      #       verb_options[code] ||= (verb_options.values.first || DEFAULTS).dup
      #       verb_options[code].merge! options
      #       @explicit_codes[verb] << code
      #     else
      #       verb_options.keys.each { |c| set_options_for_verb options, verb, code: c }
      #     end
      #   else
      #     verb_options.merge! options
      #   end
      # end
      #
      # def normalize_options(options)
      #   case options
      #     when *DEFAULTS.keys then {options => true}
      #     when Array then options.map { |x| [x, true] }.to_h
      #     when TrueClass then {requests: true, responses: true}
      #     when FalseClass then DEFAULTS.keys.map { |x| [x, false] }.to_h
      #     when :all then DEFAULTS.keys.map { |x| [x, true] }.to_h
      #     else raise "Invalid option of type #{options.class.name} : #{options}"
      #   end
      # end
      #
      # def interpret(options)
      #
      #   options.each do |option|
      #     case option
      #       when *VERBS
      #         add_verb_options option
      #         remove_implicit_verbs
      #       when Fixnum, Range
      #         add_code option
      #         remove_implicit_codes
      #       when Hash
      #         option.each { |k, v| interpret_pair k, v }
      #       when *@global.keys
      #         @global[option] = true
      #       else raise "Invalid option of type #{option.class.name} : #{option}"
      #     end
      #   end
      #
      # end
      #
      # def interpret_pair(name, value)
      #   case name
      #     when *VERBS
      #       add_verb_options name, value
      #     when Fixnum
      #       set_options value, code: name
      #     when Range
      #       name.each { |code| set_options value, code: code }
      #     when :only
      #       raise 'Must use a hash with :only =>' unless Hash === value
      #       value.each { |k, v| interpret_pair k, v }
      #       remove_implicit_verbs if value.keys.find { |k| VERBS.include? k }
      #       remove_implicit_codes if value.keys.find { |k| Range === k || Fixnum === k }
      #     else raise "Invalid option of type #{name.class.name} : #{name}"
      #   end
      # end
      #
      # def interpret_exclusive_pair(name, value)
      #   case name
      #     when *VERBS
      #       add_verb_options name, value
      #       remove_implicit_verbs
      #     when Fixnum
      #
      #   end
      # end
      #
      # def remove_implicit_codes
      #   @by_verb.each_key { |verb| remove_implicit_codes_for_verb verb }
      # end
      #
      # def remove_implicit_codes_for_verb(verb)
      #   explicit = @explicit_verbs[verb]
      #   @by_verb[verb].select! { |k, _| explicit.include? k }
      # end
      #
      # def add_code(code)
      #   use_codes!
      #   case code
      #     when Range, Array then code.each { |c| set_options true, code: c }
      #     when Fixnum then set_options true, code: code
      #     else raise "Invalid code or codes of type #{code.class.name} : #{code}"
      #   end
      # end
      #
      # def add_verb_options(verb, options = nil)
      #   use_verbs!
      #   raise "Duplicate options for verb :#{verb}" if @explicit_verbs.include? verb
      #   @explicit_verbs << verb
      #   verb_options = @by_verb[verb]
      #   case options
      #     when TrueClass, FalseClass
      #       verb_options.each_key { |k| verb_options[k] = options }
      #     when *DEFAULTS.keys
      #       verb_options.each_key { |k| verb_options[k] = options == k }
      #     when Array
      #       verb_options.each_key { |k| verb_options[k] = options.include? k }
      #   end
      # end
      #
      # # Switch from global config to per-verb config, and optionally enabled a given verb
      # def use_verbs!
      #   if @by_verb.nil?
      #     @by_verb = VERBS.map { |verb| [verb, @global] }.to_h
      #   end
      # end
      #
      # def use_codes!
      #   return if @use_codes
      #   use_verbs!
      #   @by_verb.each do |verb, verb_hash|
      #     @by_verb[verb] = (100...600).map { |code| [code, verb_hash.dup] }.to_h
      #   end
      #   @use_codes = true
      # end
      #
      # def remove_implicit_verbs
      #   @by_verb.select! { |k, _| @explicit_verbs.include? k }
      # end

    end
  end
end
