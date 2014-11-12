require_relative 'lib/rack/traffic_logger'
require_relative 'lib/rack/traffic_logger/echo'

use Rack::TrafficLogger, STDOUT, Rack::TrafficLogger::Formatter::JSON.new(pretty_print: true), :all
run Rack::TrafficLogger::Echo.new
