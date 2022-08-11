require 'rack/utils'
require 'rack/body_proxy'
require 'zlib'
require 'securerandom'

module Rack
  class TrafficLogger
    # noinspection RubyStringKeysInHashInspection
    class Request

      def initialize(logger)
        @logger = logger
        @id = SecureRandom.hex 4
        @started_at = Time.now
      end

      def start(env)
        @verb = env['REQUEST_METHOD'].downcase.to_sym
        @env = env
      end

      def finish(response)
        @code = Array === response ? response.first.to_i : 0
        @options = @logger.options.for(@verb, @code)
        if @options.basic?
          log_request @env
          log_response @env, response if @code > 0
        end
      end

      private

      BASIC_AUTH_PATTERN = /^basic ([a-z\d+\/]+={0,2})$/i

      def log_request(env)
        log 'request' do |hash|
          if @options.request_headers?
            hash.merge! env.reject { |_, v| v.respond_to? :read }
          else
            hash.merge! env.select { |k, _| BASIC_ENV_PROPERTIES.include? k }
          end

          hash['BASIC_AUTH_USERINFO'] = $1.unpack('m').first.split(':', 2) if hash['HTTP_AUTHORIZATION'] =~ BASIC_AUTH_PATTERN

          input = env['rack.input']
          if input && @options.request_bodies?
            add_body_to_hash input.tap(&:rewind).read, env['CONTENT_ENCODING'] || env['HTTP_CONTENT_ENCODING'], hash
            input.rewind
          end
        end
      end

      def log_response(env, response)
        code, headers, body = response
        code = code.to_i
        headers = HeaderHash.new(headers) if @options.response_headers? || @options.response_bodies?
        log 'response' do |hash|
          hash['http_version'] = env['HTTP_VERSION'] || 'HTTP/1.1'
          hash['status_code'] = code
          hash['status_name'] = Utils::HTTP_STATUS_CODES[code]
          hash['headers'] = headers if @options.response_headers?
          add_body_to_hash get_real_body(body), headers['Content-Encoding'], hash if @options.response_bodies?
        end
      end

      # Rack allows response bodies to be a few different things. This method
      # ensures we get a string back.
      def get_real_body(body)

        # For bodies representing temporary files
        body = ::File.open(body.path, 'rb') { |f| f.read } if body.respond_to? :path

        # For bodies representing streams
        body = body.read.tap { body.rewind } if body.respond_to? :read

        # When body is an array (the common scenario)
        body = body.join if body.respond_to? :join

        # When body is a proxy
        body = body.body while Rack::BodyProxy === body

        # It should be a string now. Just in case it's not...
        body.to_s

      end

      def add_body_to_hash(body, encoding, hash)
        body = Zlib::GzipReader.new(StringIO.new body).read if encoding == 'gzip'
        body = body.dup.force_encoding 'UTF-8'
        if body.valid_encoding?
          hash['body'] = body
        else
          hash['body_base64'] = [body].pack 'm0'
        end
      end

      def log(event)
        hash = {
            'timestamp' => Time.now.strftime('%FT%T.%3N%:z'),
            'request_log_id' => @id,
            'event' => event
        }
        yield hash rescue hash.merge! 'logger_exception' => expand_exception($!)
        @logger.log hash
      end

      def expand_exception(e)
        {
            'class' => e.class.name,
            'message' => e.message,
            'backtrace' => e.backtrace
        }
      end

    end
  end
end
