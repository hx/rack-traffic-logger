require 'faraday'
require 'json'

module Rack
  # noinspection RubyStringKeysInHashInspection
  class TrafficLogger
    describe FaradayAdapter do

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
      let(:formatter) { Formatter::JSON.new }

      let :conn do
        Faraday.new('http://domain.kom') do |conn|
          conn.request :multipart
          conn.adapter :test do |stub|
            stub.get( '/foo') { |_| [200, {'Content-Type' => 'text/plain'}, 'bar'] }
            stub.post('/foo') { |env| [201, {'Content-Type' => 'application/json'}, env.body] }
          end
          conn.headers['User-Agent'] = 'RSpec'
          conn.use *subject
        end
      end

      subject { [FaradayAdapter, logger, formatter ] }

      describe 'bugs' do
        example 'multipart requests failure' do
          conn.post '/foo', foo: Faraday::UploadIO.new(StringIO.new('hello'), 'application/x-octet-stream')
        end
      end

      describe 'request logging' do

        let(:last_request) { logger.requests.last }

        before :each do
          conn.post do |req|
            req.url '/foo?a=123'
            req.headers['Content-Type'] = 'application/json'
            req.body = JSON.generate(a:1)
          end
        end

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

          subject { [FaradayAdapter, logger, formatter, :request_headers] }

          it 'should log the content type' do
            expect(last_request['CONTENT_TYPE']).to eq 'application/json'
          end

        end

        describe 'with bodies' do

          subject { [FaradayAdapter, logger, formatter, :request_bodies] }

          it 'should log the request body' do
            expect(last_request['body']).to eq '{"a":1}'
          end

        end

      end

      describe 'response logging' do

        before :each do
          conn.post do |req|
            req.url '/foo?a=123'
            req.headers['Content-Type'] = 'application/json'
            req.body = JSON.generate(a:1)
          end
        end

        let(:last_response) { logger.responses.last }

        it 'should log responses' do
          expect(logger.responses.length).to be 1
        end

        it 'should log the response status' do
          expect(last_response['status_code']).to be 201
          expect(last_response['status_name']).to eq 'Created'
        end

        it 'should not log the response headers' do
          expect(last_response.key? 'headers').to be false
        end

        it 'should not log the response body' do
          expect(last_response.key? 'body').to be false
        end

        describe 'with headers' do

          subject { [FaradayAdapter, logger, formatter, :response_headers ] }

          it 'should log the response headers' do
            expect(last_response['headers']).to eq({'Content-Type' => 'application/json'})
          end

        end

        describe 'with bodies' do

          subject { [FaradayAdapter, logger, formatter, :response_bodies ] }

          it 'should log the response headers' do
            expect(last_response['body']).to eq '{"a":1}'
          end

        end

      end
    end
  end
end
