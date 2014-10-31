require_relative '../traffic_logger'
require 'json'

module Rack
  class TrafficLogger
    class Echo
      def call(env)
        begin
          body = JSON.parse(env['rack.input'].tap(&:rewind).read).to_json
          headers = {'Content-Type' => 'application/json'}
          if env['HTTP_ACCEPT_ENCODING'] =~ /\bgzip\b/
            zipped = StringIO.new('w')
            writer = Zlib::GzipWriter.new(zipped)
            writer.write body
            writer.close
            body = zipped.string
            headers['Content-Encoding'] = 'gzip'
          end
          [200, headers, [body]]
        rescue JSON::ParserError => error
          [
              500,
              {'Content-Type' => 'text/plain;charset=UTF-8'},
              [error.message]
          ]
        end
      end
    end
  end
end
