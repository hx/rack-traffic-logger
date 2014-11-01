require_relative 'traffic_logger/version'
require_relative 'traffic_logger/logger'
require_relative 'traffic_logger/header_hash'

require 'forwardable'
require 'rack/nulllogger'
require 'json'

module Rack
  class TrafficLogger
    extend Forwardable

    PUBLIC_ATTRIBUTES = {
        request_headers:  {type: [TrueClass, FalseClass], default: true},
        request_bodies:   {type: [TrueClass, FalseClass], default: true},
        response_headers: {type: [TrueClass, FalseClass], default: true},
        response_bodies:  {type: [TrueClass, FalseClass], default: true},
        colors: {type: [TrueClass, FalseClass], default: false},
        prevent_compression: {type: [TrueClass, FalseClass], default: false},
        pretty_print: {type: [TrueClass, FalseClass], default: false}
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
      env.delete 'HTTP_ACCEPT_ENCODING' if prevent_compression
      safely('logging request') { log_request! env }
      @app.call(env).tap { |response| safely('logging response') { log_response! env, response } }
    end

    private

    def safely(action)
      yield rescue error "Error #{action}: #{$!}"
    end

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
      if request_headers || request_bodies
        headers = HeaderHash.new(env_request_headers env)
        log_headers! headers if request_headers
        input = env['rack.input']
        if request_bodies && input
          log_body! input.read,
                    type: headers['Content-Type'],
                    encoding: headers['Content-Encoding']
          input.rewind
        end
      end
    end

    RESPONSE_TEMPLATES = {
        true => ":http \e[:color:code \e[36m:status\e[0m",
        false => ':http :code :status'
    }

    def status_color(status)
      case (status.to_i / 100).to_i
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
      if response_headers || response_bodies
        headers = HeaderHash.new(response[1])
        log_headers! headers if response_headers
        if response_bodies
          body = response[2]
          body = ::File.open(body.path, 'rb') { |f| f.read } if body.respond_to? :path
          if body.respond_to? :read
            stream = body
            body = stream.tap(&:rewind).read
            stream.rewind
          end
          body = body.join if body.respond_to? :join
          body = body.body while Rack::BodyProxy === body
          log_body! body,
                    type: headers['Content-Type'],
                    encoding: headers['Content-Encoding']
        end
      end
    end

    def log_body!(body, type: nil, encoding: nil)
      body = Zlib::GzipReader.new(StringIO.new body).read if encoding == 'gzip'
      body = JSON.pretty_generate(JSON.parse body) if type[/[^;]+/] == 'application/json' && pretty_print
      body = "<#BINARY #{body.bytes.length} bytes>" if body =~ /[^[:print:]\r\n\t]/
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
      env.select { |k, _| k =~ /^(CONTENT|HTTP)_(?!VERSION)/ }.map { |(k, v)| [k.sub(/^HTTP_/, ''), v] }.to_h
    end

  end
end
