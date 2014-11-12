module Rack
  class TrafficLogger
    # noinspection RubyStringKeysInHashInspection
    class OptionInterpreter
      describe Shorthand do

        EXPECTATIONS = {
            'ge' => [:get],
            'po' => [:post],
            'pu' => [:put],
            'pa' => [:patch],
            'de' => [:delete],
            'op' => [:options],
            'he' => [:head],
            'tr' => [:trace],
            'h' => [:headers],
            'b' => [:bodies],
            'a' => [:all],
            'ih' => [:request_headers],
            'ib' => [:request_bodies],
            'oh' => [:response_headers],
            'ob' => [:response_bodies],
            'o' => [:only],
            'f' => [false],
            '200' => [200],
            '200-204' => [200..204],
            '2**' => [200..299],
            '31*' => [310..319],
            'ge:f' => [get: false],
            'o:{ge:f}' => [only: {get: false}],
            '[pa,pu]:f' => [[:patch, :put] => false],
            '3**,2**:[ge,po]' => [300..399, 200..299 => [:get, :post]],
            'ih,401:f,5**:a,2**:{po:ib,de:f}' =>
                [:request_headers, 401 => false, 500..599 => :all, 200..299 => {post: :request_bodies, delete: false}],
            '[ge,he]:200-204,po:{o:{201:ib}},[pu,pa]:a' =>
                [[:get, :head] => 200..204, post: {only: {201 => :request_bodies}}, [:put, :patch] => :all]
        }

        describe 'transformations' do
          index = 0
          EXPECTATIONS.each do |input, expected|
            describe "example #{index += 1}" do
              it "should transform '#{input}' to #{expected}" do
                expect(Shorthand.transform input).to eq expected
              end
            end
          end
        end

      end
    end
  end
end
