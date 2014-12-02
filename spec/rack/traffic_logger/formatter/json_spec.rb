module Rack
  class TrafficLogger
    class Formatter
      describe JSON do

        it 'should be a formatter' do
          expect(subject).to be_a Formatter
        end

        it 'should format hashes as JSON' do
          expect(subject.format a: 1).to eq "{\"a\":1}\n"
        end

        describe 'pretty' do

          subject { JSON.new pretty_print: true }

          it 'should format hashes as pretty JSON' do
            expect(subject.format a: 1).to eq "{\n  \"a\": 1\n}\n"
          end

        end

      end
    end
  end
end