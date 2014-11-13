module Rack
  class TrafficLogger

    def self.use(on: nil, filter: '', log_path: '/dev/stdout', formatter: nil)
      filter = (filter || '').to_s.downcase.strip
      unless ['0', 'no', 'false', 'nil', 'none', '', 'off'].include? filter
        args = [Rack::TrafficLogger, log_path]
        args << formatter if formatter
        begin
          raise if %w[1 yes true normal basic minimal on].include? filter
          on.use *args, filter
        rescue
          on.use *args
        end
      end
    end

  end
end
