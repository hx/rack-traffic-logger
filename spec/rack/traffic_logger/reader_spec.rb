require 'json'
require 'stringio'

module Rack
  class TrafficLogger

    describe Reader do

      let(:good_hash) {{ timestamp: '2014-12-02T19:13:03.1+11:00' }}
      let(:good_input) { StringIO.new good_hash.to_json << "\n" }
      let(:good_output) { "@ Tue 02 Dec '14 19:13:03.100 #\n\n\n" }
      let(:bad_input) { StringIO.new "--\n" }
      let(:bad_output) { "--\n" }
      let :slow_input do
        StringIO.new(good_hash.to_json << "\n").tap do |s|
          class << s
            alias_method :normal_read, :read_nonblock
            def read_nonblock(*args, &block)
              unless @raised
                @raised = true
                raise IO::EAGAINWaitReadable
              end
              normal_read *args, &block
            end
          end
        end
      end
      let(:output) { double 'Output', :<< => true }

      def read(what)
        Reader.start what, output
      end

      before { allow(Signal).to receive :trap }

      describe '::start' do

        subject { Reader.start good_input, output }

        it 'should return a new Reader instance' do
          expect(subject).to be_a Reader
        end

      end

      describe 'with good input' do

        it 'should finish reading and writing on initialization' do
          expect(output).to receive(:<<).once.with(good_output)
          read good_input
        end

      end

      describe 'with bad input' do

        it 'should finish reading and writing on initialization' do
          expect(output).to receive(:<<).once.with(bad_output)
          read bad_input
        end

      end

      describe 'with slow input' do

        it 'should eventually finish reading and writing on initialization' do
          expect(output).to receive(:<<).once.with(good_output)
          read slow_input
        end

      end

    end

  end
end
