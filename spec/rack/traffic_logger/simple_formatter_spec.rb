# noinspection RubyStringKeysInHashInspection
class Rack::TrafficLogger
  describe SimpleFormatter do

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

    describe 'monochrome' do

      describe 'requests' do

        describe 'basic' do
          it 'should only return the request line' do
            expect(subject.format basic_request).to eq basic_request_formatted
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

        describe 'with headers' do
          let(:lines) { subject.format(request_with_headers).split("\n") }

          it 'should include 4 lines' do
            expect(lines.length).to be 4
          end

          include_examples 'expect_request'
          include_examples 'expect_headers'
        end

        describe 'with a body' do
          let(:lines) { subject.format(request_with_body).split("\n") }

          it 'should include 4 lines' do
            expect(lines.length).to be 4
          end

          include_examples 'expect_request'
          include_examples 'expect_body'
        end

        describe 'with a binary body' do
          let(:lines) { subject.format(request_with_binary_body).split("\n") }

          it 'should include 3 lines' do
            expect(lines.length).to be 3
          end

          include_examples 'expect_request'
          include_examples 'expect_binary_body'
        end

        describe 'with headers and a body' do
          let(:lines) { subject.format(request_with_headers_and_body).split("\n") }

          it 'should include 7 lines' do
            expect(lines.length).to be 7
          end

          include_examples 'expect_request'
          include_examples 'expect_headers'
          include_examples 'expect_body'
        end

        describe 'with headers and a binary body' do
          let(:lines) { subject.format(request_with_headers_and_binary_body).split("\n") }

          it 'should include 6 lines' do
            expect(lines.length).to be 6
          end

          include_examples 'expect_request'
          include_examples 'expect_headers'
          include_examples 'expect_binary_body'
        end

      end

    end

  end
end
