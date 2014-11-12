require_relative 'lib/rack/traffic_logger'
require_relative 'lib/rack/traffic_logger/echo'

use Rack::TrafficLogger, 'echo.log', Rack::TrafficLogger::Formatter::JSON.new, :all
run Rack::TrafficLogger::Echo.new
