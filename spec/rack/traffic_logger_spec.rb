require 'json'
require 'time'
require 'rack/traffic_logger/echo'

module Rack
  TL = TrafficLogger
  describe TrafficLogger do

    class LoggerDouble < Array
      def write(data)
        self << JSON.parse(data)
      end
      def requests
        select { |x| x['event'] == 'request' }
      end
      def responses
        select { |x| x['event'] == 'response' }
      end
    end

    let(:logger) { LoggerDouble.new }

    subject { TL.new TL::Echo.new, logger, TL::Formatter::JSON.new }

    describe 'request logging' do

      let(:last_request) { logger.requests.last }

      before { subject.call mock_env :post, '/foo?a=123', {'Content-Type' => 'application/json'}, JSON.generate({a: 1}) }

      it 'should log the request' do
        expect(logger.requests.length).to be 1
      end

      it 'should log the request method' do
        expect(last_request['REQUEST_METHOD']).to eq 'POST'
      end

      it 'should log the path' do
        expect(last_request['PATH_INFO']).to eq '/foo'
      end

      it 'should log the query string' do
        expect(last_request['QUERY_STRING']).to eq 'a=123'
      end

      it 'should not log the content type' do
        expect(last_request['CONTENT_TYPE']).to be_nil
        expect(last_request['HTTP_CONTENT_TYPE']).to be_nil
      end

      it 'should not log the body' do
        expect(last_request['body']).to be_nil
        expect(last_request['body_base64']).to be_nil
      end

      it 'should have a timestamp' do
        time = Time.parse(last_request['timestamp'])
        expect(Time.now - time).to be < 5
      end

      describe 'with headers' do

        subject { TL.new TL::Echo.new, logger, TL::Formatter::JSON.new, :request_headers }

        it 'should log the content type' do
          expect(last_request['CONTENT_TYPE']).to eq 'application/json'
        end

      end

      describe 'with bodies' do

        subject { TL.new TL::Echo.new, logger, TL::Formatter::JSON.new, :request_bodies }

        it 'should log the request body' do
          expect(last_request['body']).to eq '{"a":1}'
        end

      end

      describe 'request log ID' do

        let(:request_log_id) { last_request['request_log_id'] }

        it 'should be an 8-digit random hex string' do
          expect(request_log_id).to match /^[a-f\d]{8}$/
        end

        it 'should be equal for both request and response' do
          expect(request_log_id).to eq logger.responses.last['request_log_id']
        end

        it 'should be different between requests' do
          subject.call mock_env
          expect(request_log_id).to_not eq logger.requests.first['request_log_id']
        end

      end

    end

    describe 'response logging' do

      let(:last_response) { logger.responses.last }

      before { subject.call mock_env :post, '/', {}, JSON.generate({foo: 'bar'}) }

      it 'should log the response' do
        expect(logger.responses.length).to be 1
      end

      it 'should log the response status' do
        expect(last_response['status_code']).to be 200
        expect(last_response['status_name']).to eq 'OK'
      end

      it 'should not log the response headers' do
        expect(last_response.key? 'headers').to be false
      end

      it 'should not log the response body' do
        expect(last_response.key? 'body').to be false
      end

      describe 'with headers' do

        subject { TL.new TL::Echo.new, logger, TL::Formatter::JSON.new, :response_headers }

        it 'should log the response headers' do
          expect(last_response['headers']).to eq({'Content-Type' => 'application/json'})
        end

      end

      describe 'with bodies' do

        subject { TL.new TL::Echo.new, logger, TL::Formatter::JSON.new, :response_bodies }

        it 'should log the response headers' do
          expect(last_response['body']).to eq '{"foo":"bar"}'
        end

        describe 'that are compressed' do

          before { subject.call mock_env :post, '/', {'Accept-Encoding' => 'gzip'}, JSON.generate({hello: :goodbye}) }

          it 'should decompress the result' do
            expect(last_response['body']).to eq '{"hello":"goodbye"}'
          end

        end

        describe 'that are binary' do

          let(:binary) { (0..255).reduce(''.force_encoding Encoding::ASCII_8BIT) { |x, n| x << n } }
          before { subject.call mock_env :post, '/', {}, binary }

          it 'should log the response body as base64' do
            expect(last_response.key? 'body').to be false
            expect(last_response['body_base64']).to eq [binary].pack('m0')
          end

        end

      end

    end

  end
end
