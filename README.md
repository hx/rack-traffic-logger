# Rack::TrafficLogger

This is simple Rack middleware for logging incoming/outgoing HTTP/S traffic.

## Installation

```bash
gem install rack-traggic-logger
```

## Usage

```ruby
require 'rack/traffic_logger'
```

Then, in your `config.ru` or wherever you set up your middleware stack:

```ruby
use Rack::TrafficLogger, 'path/to/file.log', response_bodies: false, colors: true
```

- If you don't provide a log, everything will go to `STDOUT`.
- You can supply either the path to a log file, an open file handle, or an instance of `Logger`.
- See [this file](https://github.com/hx/rack-traffic-logger/blob/develop/lib/rack/traffic_logger.rb) for a list of other options that can affect logging style/filtering.
