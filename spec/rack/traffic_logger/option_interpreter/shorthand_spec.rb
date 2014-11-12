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
            '200' => [200],
            '200-204' => [200..204],
            '2**' => [200..299],
            '31*' => [310..319],
            '!ge' => [get: false],
            '+!ge' => [only: {get: false}],
            '![pa,pu]' => [[:patch, :put] => false],
            '3**,2**:[ge,po]' => [300..399, 200..299 => [:get, :post]],
            'ih,!401,5**:a,2**:{po:ib,!de}' => [:request_headers, 401 => false, 500...600 => :all, 200...300 => {post: :request_bodies, delete: false}],
            '[ge,he]:200-204,po:+{201:ib},[pu,pa]:a' => [[:get, :head] => 200..204, post: {only: {201 => :request_bodies}}, [:put, :patch] => :all]
        }

        describe 'transformations' do
          EXPECTATIONS.each do |input, expected|
            describe "input '#{input}'" do
              it "should transform to #{expected}" do
                expect(Shorthand.transform input).to eq output
              end
            end
          end
        end

      end
    end
  end
end
