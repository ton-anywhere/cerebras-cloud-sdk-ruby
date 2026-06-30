require_relative 'client'

module Cerebras
  class Chat
    attr_reader :client

    def initialize(client)
      @client = client
    end

    def completions
      @completions ||= Completions.new(self)
    end

    class Completions
      def initialize(chat)
        @chat = chat
      end

      def create(params = {}, &block)
        client = @chat.client
        path = '/chat/completions'
        
        if params[:stream] && block_given?
          buffer = ""
          state = { current_event_data: nil }
          client.request(:post, path, { stream: true }, params) do |chunk|
            client.parse_sse(chunk, buffer, state) do |data|
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
          client.request(:post, path, {}, params)
        end
      end
    end
  end
end
