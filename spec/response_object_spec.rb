require 'rspec'
require 'ostruct'
require_relative '../lib/cerebras'

RSpec.describe 'Cerebras Response Objects' do
  let(:client) { Cerebras::Client.new(api_key: 'test_key', warm_connection: false) }
  let(:mock_body) { { 'id' => 'chatcmpl-123', 'choices' => [{ 'message' => { 'content' => 'Hello' } }] } }
  let(:conn) { double('connection') }
  let(:response) { double('response', body: mock_body) }

  before do
    allow(client).to receive(:connection).and_return(conn)
    allow(conn).to receive(:get).and_return(response)
  end

  let(:result) { client.request(:get, '/test') }

  it 'supports dot-notation access for the id' do
    expect(result.id).to eq('chatcmpl-123')
  end

  it 'supports nested dot-notation access for message content' do
    expect(result.choices.first.message.content).to eq('Hello')
  end

  it 'is not an OpenStruct' do
    expect(result.class).not_to eq(OpenStruct)
  end
end
