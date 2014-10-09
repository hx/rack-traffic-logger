# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rack/traffic_logger/version'

Gem::Specification.new do |spec|
  spec.name          = 'rack-traffic-logger'
  spec.version       = Rack::TrafficLogger::VERSION
  spec.authors       = ['Neil E. Pearson']
  spec.email         = ['neil@helium.net.au']
  spec.summary       = %q{Rack Raw HTTP Traffic Logger}
  spec.description   = %q{Rack Middleware for logging raw incoming/outgoing HTTP traffic}
  spec.homepage      = 'https://github.com/hx/rack-traffic-logger'
  spec.license       = 'MIT'

  spec.files         = Dir['README*', 'LICENSE*', '{lib}/**/*.rb'] & `git ls-files -z`.split("\x0")
  spec.require_paths = ['lib']

  spec.add_dependency 'rack', '~> 1'
end
