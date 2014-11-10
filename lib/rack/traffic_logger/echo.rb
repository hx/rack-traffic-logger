require_relative '../traffic_logger'
require 'json'

module Rack
  class TrafficLogger
    class Echo
      def call(env)
        body = env['rack.input'].tap(&:rewind).read
        headers = {}
        begin
          body = JSON.parse(body).to_json
          headers['Content-Type'] = 'application/json'
        rescue JSON::ParserError
          # ignored
        end
        if env['HTTP_ACCEPT_ENCODING'] =~ /\bgzip\b/
          zipped = StringIO.new('w')
          writer = Zlib::GzipWriter.new(zipped)
          writer.write body
          writer.close
          body = zipped.string
          headers['Content-Encoding'] = 'gzip'
        end
        [200, headers, [body]]
      end
    end
  end
end
