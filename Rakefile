require "bundler/gem_tasks"
require 'thin'
require 'rack/traffic_logger/echo'

task :echo do
  Thin::Server.start '127.0.0.1', 1962 do
    use Rack::TrafficLogger, STDOUT
    run Rack::TrafficLogger::Echo.new
  end
end
