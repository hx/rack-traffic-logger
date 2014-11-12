# noinspection RubyStringKeysInHashInspection
class Rack::TrafficLogger
  describe StreamSimulator do

    let(:basic_request) {{
        event: 'request',
        'REQUEST_METHOD' => 'POST',
        'PATH_INFO' => '/foo/bar',
        'QUERY_STRING' => 'xyz=123',
        'HTTP_VERSION' => 'HTTP/1.1'
    }}

    let(:basic_request_formatted) { 'POST /foo/bar?xyz=123 HTTP/1.1' }

    let(:request_headers) {{
        'CONTENT_TYPE' => 'text/plain',
        'HTTP_X_SOMETHING' => 'this',
        'HTTP_AUTHORIZATION' => 'Basic Zm9vOmJhcg==' # foo:bar
    }}

    let(:request_with_headers) { basic_request.merge request_headers }

    let(:text_body) { "First line of body\nSecond line of body" }
    let(:binary_body) { (0..255).reduce(''.force_encoding Encoding::ASCII_8BIT) { |x, n| x << n } }

    let(:request_with_body) { basic_request.merge 'body' => text_body }
    let(:request_with_binary_body) { basic_request.merge 'body_base64' => [binary_body].pack('m0') }

    let(:request_with_headers_and_body) { request_with_body.merge request_headers }
    let(:request_with_headers_and_binary_body) { request_with_binary_body.merge request_headers }

    let(:basic_response) {{
        event: 'response',
        'http_version' => 'HTTP/1.1',
        'status_code' => 201,
        'status_name' => 'Created'
    }}

    let(:basic_response_formatted) { 'HTTP/1.1 201 Created' }

    let(:response_headers) {{'headers' => {
        'content-length' => text_body.length.to_s,
        'content-type' => 'text/plain'
    }}}

    let(:response_with_headers) { basic_response.merge response_headers }

    let(:response_with_body) { basic_response.merge 'body' => text_body }
    let(:response_with_binary_body) { basic_response.merge 'body_base64' => [binary_body].pack('m0') }

    let(:response_with_headers_and_body) { response_with_body.merge response_headers }
    let(:response_with_headers_and_binary_body) { response_with_binary_body.merge response_headers }

    def format(input)
      @result = subject.format(input)
    end

    let(:result) { @result }
    let(:lines) { result.split "\n" }

    describe 'monochrome' do

      shared_examples 'expect_body' do
        it 'should include a blank line between the request/headers and the body' do
          expect(lines[-3]).to eq ''
        end

        it 'should include the body' do
          expect(lines[-2]).to eq 'First line of body'
          expect(lines[-1]).to eq 'Second line of body'
        end
      end

      shared_examples 'expect_binary_body' do
        it 'should include a blank line between the request and the body' do
          expect(lines[-2]).to eq ''
        end

        it 'should include a placeholder indicating the length of the binary data' do
          expect(lines.last).to eq '<BINARY (256 bytes)>'
        end
      end

      describe 'requests' do

        describe 'basic' do
          before { format basic_request }
          it 'should only return the request line' do
            expect(result).to eq basic_request_formatted
          end
        end

        shared_examples 'expect_request' do
          it 'should include the request line' do
            expect(lines.first).to eq basic_request_formatted
          end
        end

        shared_examples 'expect_headers' do
          it 'should include the content-type header' do
            expect(lines[1..3]).to include 'Content-Type: text/plain'
          end

          it 'should include the authorization header' do
            expect(lines[1..3]).to include 'Authorization: Basic Zm9vOmJhcg== foo:bar'
          end

          it 'should include the custom header' do
            expect(lines[1..3]).to include 'X-Something: this'
          end
        end

        describe 'with headers' do
          before { format request_with_headers }

          it 'should include 4 lines' do
            expect(lines.length).to be 4
          end

          include_examples 'expect_request'
          include_examples 'expect_headers'
        end

        describe 'with a body' do
          before { format request_with_body }

          it 'should include 4 lines' do
            expect(lines.length).to be 4
          end

          include_examples 'expect_request'
          include_examples 'expect_body'
        end

        describe 'with a binary body' do
          before { format request_with_binary_body }

          it 'should include 3 lines' do
            expect(lines.length).to be 3
          end

          include_examples 'expect_request'
          include_examples 'expect_binary_body'
        end

        describe 'with headers and a body' do
          before { format request_with_headers_and_body }

          it 'should include 7 lines' do
            expect(lines.length).to be 7
          end

          include_examples 'expect_request'
          include_examples 'expect_headers'
          include_examples 'expect_body'
        end

        describe 'with headers and a binary body' do
          before { format request_with_headers_and_binary_body }

          it 'should include 6 lines' do
            expect(lines.length).to be 6
          end

          include_examples 'expect_request'
          include_examples 'expect_headers'
          include_examples 'expect_binary_body'
        end

      end

      describe 'responses' do

        describe 'basic' do
          before { format basic_response }
          it 'should include the response status' do
            expect(result).to eq basic_response_formatted
          end
        end

        shared_examples 'expect_status' do
          it 'should include the response status' do
            expect(lines.first).to eq basic_response_formatted
          end
        end

        shared_examples 'expect_headers' do
          it 'should include the content-length header' do
            expect(lines[1..2]).to include "Content-Length: #{text_body.length}"
          end

          it 'should include the content-type header' do
            expect(lines[1..2]).to include 'Content-Type: text/plain'
          end
        end

        describe 'with headers' do
          before { format response_with_headers }

          it 'should have 3 lines' do
            expect(lines.length).to be 3
          end

          include_examples 'expect_status'
          include_examples 'expect_headers'
        end

        describe 'with body' do
          before { format response_with_body }

          it 'should have 4 lines' do
            expect(lines.length).to be 4
          end

          include_examples 'expect_status'
          include_examples 'expect_body'
        end

        describe 'with binary body' do
          before { format response_with_binary_body }

          it 'should have 3 lines' do
            expect(lines.length).to be 3
          end

          include_examples 'expect_status'
          include_examples 'expect_binary_body'
        end

        describe 'with headers and body' do
          before { format response_with_headers_and_body }

          it 'should have 6 lines' do
            expect(lines.length).to be 6
          end

          include_examples 'expect_status'
          include_examples 'expect_headers'
          include_examples 'expect_body'
        end

        describe 'with headers and binary body' do
          before { format response_with_headers_and_binary_body }

          it 'should have 5 lines' do
            expect(lines.length).to be 5
          end

          include_examples 'expect_status'
          include_examples 'expect_headers'
          include_examples 'expect_binary_body'
        end

      end

    end

    describe 'pretty print' do

      subject { StreamSimulator.new pretty_print: true }

      describe 'requests' do
        let(:input) { basic_request.merge 'CONTENT_TYPE' => 'application/json', 'body' => {a: 1}.to_json }

        it 'should pretty-print JSON bodies' do
          expected = '
POST /foo/bar?xyz=123 HTTP/1.1
Content-Type: application/json

{
  "a": 1
}
          '.strip
          expect(subject.format input).to eq expected
        end
      end

      describe 'responses' do
        let(:input) { basic_response.merge 'headers' => {'Content-Type' => 'application/json'}, 'body' => {a: 1}.to_json }

        it 'should pretty-print JSON bodies' do
          expected = '
HTTP/1.1 201 Created
Content-Type: application/json

{
  "a": 1
}
          '.strip
          expect(subject.format input).to eq expected
        end
      end

    end
  end
end
