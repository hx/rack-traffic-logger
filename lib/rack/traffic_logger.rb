require_relative 'traffic_logger/version'
require_relative 'traffic_logger/logger'

require 'forwardable'
require 'rack/nulllogger'

module Rack
  class TrafficLogger
    extend Forwardable

    PUBLIC_ATTRIBUTES = {
        request_headers:  {type: [TrueClass, FalseClass], default: true},
        request_bodies:   {type: [TrueClass, FalseClass], default: true},
        response_headers: {type: [TrueClass, FalseClass], default: true},
        response_bodies:  {type: [TrueClass, FalseClass], default: true},
        colors: {type: [TrueClass, FalseClass], default: false}
    }

    PUBLIC_ATTRIBUTES.each do |attr, props|
      type = props[:type]
      type = [type] unless Array === type
      define_method(attr) { @options[attr] }
      define_method :"#{attr}=" do |value|
        raise "Expected one of [#{type.map(&:name).join ' | '}], got #{value.class.name}" unless type.find { |t| t === value }
        @options[attr] = value
      end
    end

    delegate %i(info debug warn error fatal) => :@logger

    def initialize(app, logger = nil, options = {})
      Raise "Expected a Hash, but got #{options.class.name}" unless Hash === options
      @app = app
      case logger
        when nil, false then logger = Logger.new(STDOUT)
        when String, IO then logger = Logger.new(logger)
        else logger = Rack::NullLogger.new(nil) unless logger.respond_to? :debug
      end
      @logger = logger
      @options = self.class.default_options.merge(options)
    end

    def call(env)
      log_request! env
      @app.call(env).tap { |response| log_response! env, response }
    end

    private

    def self.default_options
      @default_options ||= PUBLIC_ATTRIBUTES.map { |k, v| [k, v[:default]] }.to_h
    end

    REQUEST_TEMPLATES = {
        true => "%s %s%s %s",
        false => "%s %s%s %s"
    }

    def log_request!(env)
      debug REQUEST_TEMPLATES[colors] % [
        env['REQUEST_METHOD'],
        env['PATH_INFO'],
        (q = env['QUERY_STRING']).empty? ? '' : "?#{q}",
        env['HTTP_VERSION'] || 'HTTP/1.1'
      ]
      log_headers! env_request_headers(env) if request_headers
      input = env['rack.input']
      if request_bodies && input
        log_body! input.read
        input.rewind
      end
    end

    RESPONSE_TEMPLATES = {
        true => "%s %s %s",
        false => "%s %s %s"
    }

    def log_response!(env, response)
      debug RESPONSE_TEMPLATES[colors] % [
          env['HTTP_VERSION'] || 'HTTP/1.1',
          code = response[0],
          Rack::Utils::HTTP_STATUS_CODES[code]
      ]
      log_headers! response[1] if response_headers
      log_body! response[2].join if response_bodies
    end

    def log_body!(body)
      info body
    end

    HEADER_TEMPLATES = {
        true => "%s: %s\n",
        false => "%s: %s\n"
    }

    def log_headers!(headers)
      info headers.map { |k, v| HEADER_TEMPLATES[colors] % [k, v] }.join
    end

    def env_request_headers(env)
      env.select do |k, _|
        k =~ /^(CONTENT|HTTP)_/
      end.map do |(k, v)|
        [
            k.sub(/^HTTP_/, '').split(/[_ -]/).map do |word|
              word[0].upcase << word[1..-1].downcase
            end.join('-'),
            v
        ]
      end.to_h
    end

  end
end
