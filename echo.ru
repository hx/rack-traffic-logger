require_relative 'lib/rack/traffic_logger'
require_relative 'lib/rack/traffic_logger/echo'

use Rack::TrafficLogger, STDOUT, colors: true, pretty_print: true
run Rack::TrafficLogger::Echo.new
