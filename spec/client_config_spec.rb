require 'rspec'
require_relative '../lib/cerebras'

RSpec.describe Cerebras::Client do
  let(:api_key) { 'test_key' }

  it 'uses default base URL' do
    client = Cerebras::Client.new(api_key: api_key, warm_connection: false)
    expect(client.connection.url_prefix.to_s).to eq('https://api.cerebras.ai/')
  end

  it 'uses ENV["CEREBRAS_BASE_URL"]' do
    stub_const('ENV', ENV.to_h.merge('CEREBRAS_BASE_URL' => 'https://custom.ai'))
    client = Cerebras::Client.new(api_key: api_key, warm_connection: false)
    expect(client.connection.url_prefix.to_s).to eq('https://custom.ai/')
  end

  it 'uses base_url provided in constructor' do
    client = Cerebras::Client.new(api_key: api_key, base_url: 'https://provided.ai', warm_connection: false)
    expect(client.connection.url_prefix.to_s).to eq('https://provided.ai/')
  end

  it 'uses a custom connection' do
    custom_conn = Faraday.new(url: 'https://custom-conn.ai')
    client = Cerebras::Client.new(api_key: api_key, connection: custom_conn, warm_connection: false)
    expect(client.connection).to eq(custom_conn)
    expect(client.connection.url_prefix.to_s).to eq('https://custom-conn.ai/')
  end
end
