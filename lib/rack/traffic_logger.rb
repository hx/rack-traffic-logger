require_relative 'traffic_logger/version'
require_relative 'traffic_logger/header_hash'
require_relative 'traffic_logger/option_interpreter'
require_relative 'traffic_logger/stream_simulator'
require_relative 'traffic_logger/formatter'
require_relative 'traffic_logger/reader'
require_relative 'traffic_logger/express_setup'
require_relative 'traffic_logger/request'
require_relative 'traffic_logger/faraday_adapter'

require 'json'
require 'securerandom'

module Rack
  class TrafficLogger

    # These environment properties will always be logged as part of request logs
    BASIC_ENV_PROPERTIES = %w[
        REQUEST_METHOD
        HTTPS
        SERVER_NAME
        SERVER_PORT
        PATH_INFO
        QUERY_STRING
        HTTP_VERSION
        REMOTE_HOST
        REMOTE_ADDR
      ]

    attr_reader :options

    def initialize(app, log_path, *options)
      @app = app
      @log_path = log_path
      @formatter = options.first.respond_to?(:format) ? options.shift : Formatter::Stream.new
      @options = OptionInterpreter.new(*options)
    end

    def call(env)
      request = Request.new(self)
      request.start env
      response = nil
      begin
        response = @app.call(env)
      ensure
        request.finish response
      end
      response
    end

    def log(hash)
      write @formatter.format hash
    end

    def write(data)
      if @log_path.respond_to? :write
        @log_path.write data
      else
        ::File.write @log_path, data, mode: 'a', encoding: data.encoding
      end
    end

  end
end
