require 'rspec'
require_relative '../lib/cerebras'
require_relative '../lib/cerebras/client'
require_relative '../lib/cerebras/chat'
require_relative '../lib/cerebras/completions'
require_relative '../lib/cerebras/errors'

RSpec.describe Cerebras::Client do
  let(:api_key) { 'test_key' }
  let(:client) { Cerebras::Client.new(api_key: api_key, warm_connection: false) }

  describe '#initialize' do
    it 'raises error if api_key is missing' do
      stub_const('ENV', ENV.to_h.merge('CEREBRAS_API_KEY' => nil))
      expect { Cerebras::Client.new(api_key: nil) }.to raise_error(Cerebras::APIConnectionError)
    end
  end

  describe '#inspect' do
    it 'includes the redaction string for the api_key' do
      expect(client.inspect).to include('api_key=[REDACTED]')
    end

    it 'does not include the actual api_key' do
      expect(client.inspect).not_to include(api_key)
    end
  end

  describe '#request' do
    it 'raises RateLimitError on 429' do
      conn = double('connection')
      allow(client).to receive(:connection).and_return(conn)
      
      # Mock Faraday::ClientError for 429
      response = double('response', :status => 429)
      error = Faraday::ClientError.new('Rate limit exceeded', response)
      allow(conn).to receive(:get).and_raise(error)

      expect { client.request(:get, '/test') }.to raise_error(Cerebras::RateLimitError)
    end

    it 'raises BadRequestError on 400' do
      conn = double('connection')
      allow(client).to receive(:connection).and_return(conn)
      
      response = double('response', :status => 400)
      error = Faraday::ClientError.new('Bad request', response)
      allow(conn).to receive(:get).and_raise(error)

      expect { client.request(:get, '/test') }.to raise_error(Cerebras::BadRequestError)
    end
  end
end

RSpec.describe Cerebras::Chat do
  let(:client) { instance_double(Cerebras::Client) }
  let(:chat) { Cerebras::Chat.new(client) }

  describe '#create' do
      context 'when calling the endpoint' do
        let(:result) { chat.completions.create(model: 'gemma-4') }

        it 'calls client request with correct path' do
          expect(client).to receive(:request).with(:post, '/chat/completions', {}, { model: 'gemma-4' })
          result
        end
      end



    it 'handles streaming SSE data' do
      # We want to test the integration between Chat#create and Client#parse_sse
      # Use a real client but mock the network request.
      real_client = Cerebras::Client.new(api_key: 'test_key', warm_connection: false)
      chat = Cerebras::Chat.new(real_client)
      
      # Mock the request to simulate raw SSE chunks coming from the server
      allow(real_client).to receive(:request).with(:post, '/chat/completions', { stream: true }, any_args) do |_, _, _, _, &block|
        block.call("data: {\"text\": \"Hello\"}\n\n")
        block.call("data: {\"text\": \" world\"}\n\n")
        block.call("data: [DONE]\n\n")
      end

      results = []
      chat.completions.create({ stream: true }, &proc { |chunk| results << chunk })
      expect(results[0]).to be_a(Cerebras::ResponseWrapper)
      expect(results[0].text).to eq("Hello")
      expect(results[1].text).to eq(" world")
    end
  end
end

RSpec.describe Cerebras::Completions do
  let(:client) { instance_double(Cerebras::Client) }
  let(:completions) { Cerebras::Completions.new(client) }

  describe '#create' do
    context 'when calling the endpoint' do
      it 'calls client request with correct path' do
        expect(client).to receive(:request).with(:post, '/completions', {}, { prompt: 'Hello' })
        completions.create(prompt: 'Hello')
      end
    end
  end
end
