require 'rspec'
require_relative '../lib/cerebras'

RSpec.describe Cerebras::Client do
  let(:api_key) { 'test_key' }
  let(:client) { Cerebras::Client.new(api_key: api_key, warm_connection: false) }

  describe '#parse_sse' do
    it 'buffers multi-line data and yields when a blank line is encountered' do
      buffer = ""
      results = []
      
      # Sequence based on common SSE: a line starting with 'data: '
      # then a blank line sequence.
      
      # Chunk 1: "data: Hello\n"
      client.send(:parse_sse, "data: Hello\n", buffer, { current_event_data: nil }) { |d| results << d }
      expect(results).to be_empty
      
      # Chunk 2: "data: World\n"
      # We must pass the SAME state object to maintain the buffer across calls.
      state = { current_event_data: "Hello\n" }
      client.send(:parse_sse, "data: World\n", buffer, state) { |d| results << d }
      expect(results).to be_empty
      
      # Chunk 3: "\n" (the terminator)
      client.send(:parse_sse, "\n", buffer, state) { |d| results << d }
      expect(results).to eq(["Hello\nWorld"])
    end

    it 'handles multiple events in one chunk' do
      buffer = ""
      results = []
      
      chunk = "data: event1\n\ndata: event2\n\n"
      client.send(:parse_sse, chunk, buffer, { current_event_data: nil }) { |d| results << d }
      
      expect(results).to eq(["event1", "event2"])
    end
  end
end
