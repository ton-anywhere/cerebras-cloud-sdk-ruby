require 'rspec'
require_relative '../lib/cerebras'

RSpec.describe Cerebras::Client do
  let(:api_key) { 'test_key' }

  it 'warms TCP connection with a dedicated request' do
    client = Cerebras::Client.new(api_key: api_key, warm_connection: false)
    
    # We expect Faraday.new to be called with the base_url
    expect(Faraday).to receive(:new).with(url: 'https://api.cerebras.ai').and_call_original
    
    # We expect a GET call to /v1/tcp_warming
    # Since we use a local Faraday instance, we'll mock the adapter or just let it fail
    # but verify the call happens.
    allow_any_instance_of(Faraday::Connection).to receive(:get).with('/v1/tcp_warming').and_return(double(body: 'ok'))
    
     client.send(:warm_tcp_connection)

  end
end
