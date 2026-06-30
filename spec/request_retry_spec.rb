require 'rspec'
require_relative '../lib/cerebras'

RSpec.describe Cerebras::Client do
  let(:api_key) { 'test_key' }
  let(:client) { Cerebras::Client.new(api_key: api_key, warm_connection: false) }

  describe '#request timeout handling' do
    it 'extracts timeout from options and applies it to request options' do
      conn = double('connection')
      allow(client).to receive(:connection).and_return(conn)
      
      req = double('request')
      allow(req).to receive(:headers).and_return({})
      allow(req).to receive(:params=)
      allow(req).to receive(:body=)
      
      options_struct = Struct.new(:timeout).new(nil)
      allow(req).to receive(:options).and_return(options_struct)

      response = double('response', body: 'ok')
      allow(conn).to receive(:post).and_yield(req).and_return(response)

      client.request(:post, '/test', { timeout: 10 }, { foo: 'bar' })
      
      expect(options_struct.timeout).to eq(10)
      expect(req).to have_received(:params=).with(hash_excluding(:timeout))
    end
  end
end
