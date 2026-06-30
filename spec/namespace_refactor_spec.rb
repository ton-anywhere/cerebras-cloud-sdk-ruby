require 'rspec'
require_relative '../lib/cerebras'

RSpec.describe 'Cerebras Namespace Refactor' do
  let(:api_key) { 'test_key' }
  let(:client) { Cerebras::Client.new(api_key: api_key, warm_connection: false) }

  it 'allows access via client.chat.completions.create' do
    # Checking if the method chain is reachable
    expect(client.chat).to respond_to(:completions)
    expect(client.chat.completions).to respond_to(:create)
  end

  it 'fails when calling client.chat.create' do
    expect { client.chat.create }.to raise_error(NoMethodError)
  end
end
