module Rack
  class TrafficLogger
    # noinspection RubyStringKeysInHashInspection
    class FaradayAdapter < TrafficLogger

      def call(request_env)
        rack_env = convert_request(request_env)
        request = Request.new(self)
        request.start rack_env
        @app.call(request_env).on_complete do |response_env|
          rack_response = convert_response(response_env)
          request.finish rack_response
        end
      end

      private

      def convert_request(faraday_env)
        url = faraday_env.url
        {
            'REQUEST_METHOD' => faraday_env.method.to_s.upcase,
            'SERVER_NAME' => url.host,
            'SERVER_PORT' => url.port,
            'PATH_INFO' => url.path,
            'HTTP_VERSION' => 'HTTP/1.1', # TODO: can this be obtained?
            'REMOTE_HOST' => 'localhost',
            'REMOTE_ADDR' => '127.0.0.1'
        }.tap do |hash|
          hash['HTTPS'] = 'on' if url.scheme == 'https'
          hash['QUERY_STRING'] = url.query if url.query
          hash.merge!(faraday_env.request_headers.map do |k, v|
            k = k.gsub('-', '_').upcase
            k = "HTTP_#{k}" unless k.start_with? 'CONTENT_'
            [k, v]
          end.to_h)
          hash['rack.input'] = StringIO.new(faraday_env.body) if faraday_env.body
        end
      end

      def convert_response(faraday_env)
        [
            faraday_env.status,
            faraday_env.response_headers,
            [faraday_env.body]
        ]
      end

    end
  end
end
