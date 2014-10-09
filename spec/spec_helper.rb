require 'rack/mock'
require 'rack/traffic_logger'

# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

end

def mock_env(verb, path, headers, body)
  Rack::MockRequest.env_for(path, input: body, method: verb).tap do |env|
    headers.each do |key, value|
      key = key.to_s.upcase.gsub(/[- ]/, '_')
      env[key =~ /^CONTENT_/ ? key : "HTTP_#{key}"] = value
    end
  end
end
