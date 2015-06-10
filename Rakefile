require "bundler/gem_tasks"
require 'thin'
require 'rack/traffic_logger/echo'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new :spec

task :echo do
  Thin::Server.start '127.0.0.1', 1962 do
    use Rack::TrafficLogger, STDOUT, colors: true
    run Rack::TrafficLogger::Echo.new
  end
end
