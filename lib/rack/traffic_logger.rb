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

    def render(template, data)
      template.gsub(/:(\w+)/) { data[$1.to_sym] }
    end

    REQUEST_TEMPLATES = {
        true => "\e[35m:verb \e[36m:path:qs\e[0m :http",
        false => ':verb :path:qs :http'
    }

    def log_request!(env)
      debug render REQUEST_TEMPLATES[colors],
                   verb: env['REQUEST_METHOD'],
                   path: env['PATH_INFO'],
                   qs: (q = env['QUERY_STRING']).empty? ? '' : "?#{q}",
                   http: env['HTTP_VERSION'] || 'HTTP/1.1'
      log_headers! env_request_headers(env) if request_headers
      input = env['rack.input']
      if request_bodies && input
        log_body! input.read
        input.rewind
      end
    end

    RESPONSE_TEMPLATES = {
        true => ":http \e[:color:code \e[36m:status\e[0m",
        false => ':http :code :status'
    }

    def status_color(status)
      case (status / 100).to_i
        when 2 then '32m'
        when 4, 5 then '31m'
        else '33m'
      end
    end

    def log_response!(env, response)
      debug render RESPONSE_TEMPLATES[colors],
                   http: env['HTTP_VERSION'] || 'HTTP/1.1',
                   code: code = response[0],
                   status: Rack::Utils::HTTP_STATUS_CODES[code],
                   color: status_color(code)
      log_headers! response[1] if response_headers
      log_body! response[2].join if response_bodies
    end

    def log_body!(body)
      info body
    end

    HEADER_TEMPLATES = {
        true => "\e[4m:key\e[0m: :val\n",
        false => ":key: :val\n"
    }

    def log_headers!(headers)
      info headers.map { |k, v| render HEADER_TEMPLATES[colors], key: k, val: v }.join
    end

    def env_request_headers(env)
      env.select do |k, _|
        k =~ /^(CONTENT|HTTP)_(?!VERSION)/
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
