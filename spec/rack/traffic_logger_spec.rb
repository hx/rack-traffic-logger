require 'rack/traffic_logger/echo'

module Rack
  describe TrafficLogger do

    let(:logger) { double 'Logger', debug: true, info: true }

    subject { TrafficLogger.new(TrafficLogger::Echo.new, logger) }

    it 'should delegate #debug, #info etc to the given logger' do
      expect(logger).to receive(:debug).with('foo').ordered
      expect(logger).to receive(:info).with('bar').ordered
      subject.debug 'foo'
      subject.info 'bar'
    end

    describe 'log output' do

      let(:body) {JSON.generate [
          200,
          {
              'Content-Type' => 'text/plain;charset=ISO-8859-1',
              'X-Foo' => 'bar'
          },
          ['response']
      ]}
      before do
        verb = :post
        path = '/path?query=string'
        headers = {
            'content-type' => 'text/plain',
            'x-custom' => 'custom!'
        }
        subject.call mock_env verb, path, headers, body
      end

      it 'should log the entire request/response' do

        # Request
        expect(logger).to have_received(:debug).ordered.with('POST /path?query=string HTTP/1.1')

        # Request headers
        expected_headers = "Content-Length: #{body.length}\nContent-Type: text/plain\nX-Custom: custom!\n"
        expect(logger).to have_received(:info).ordered.with expected_headers

        # Request body
        expect(logger).to have_received(:info).ordered.with body

        # Response
        expect(logger).to have_received(:debug).ordered.with('HTTP/1.1 200 OK')

        # Response headers
        expected_headers = "Content-Type: text/plain;charset=ISO-8859-1\nX-Foo: bar\n"
        expect(logger).to have_received(:info).ordered.with expected_headers

        # Response body
        expect(logger).to have_received(:info).ordered.with 'response'

      end

    end

  end
end