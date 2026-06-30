require_relative 'client'

module Cerebras
  class Completions
    def initialize(client)
      @client = client
    end

    def create(params = {}, &block)
      path = '/completions'
      
      if params[:stream] && block_given?
        buffer = ""
        state = { current_event_data: nil }
        @client.request(:post, path, { stream: true }, params) do |chunk|
          @client.parse_sse(chunk, buffer, state) do |data|
            next if data == '[DONE]'
            begin
              parsed_data = JSON.parse(data)
              yield ResponseWrapper.new(parsed_data)
            rescue JSON::ParserError => e
              warn "Cerebras SDK: Failed to parse SSE JSON chunk: #{e.message}"
            end
          end
        end
      else
        @client.request(:post, path, {}, params)
      end
    end
  end
end
