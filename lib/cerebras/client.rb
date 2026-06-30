require 'faraday'
require 'faraday/retry'
require 'json'
require_relative 'errors'

module Cerebras
  class Client
    # Removed attr_reader :api_key for security

    def initialize(api_key: nil, base_url: nil, connection: nil, max_retries: 2, timeout: 60, warm_connection: true)
      @api_key = api_key || ENV['CEREBRAS_API_KEY']
      raise APIConnectionError, "API key is required. Provide it via initialize or CEREBRAS_API_KEY environment variable." if @api_key.nil?

      @base_url = base_url || ENV['CEREBRAS_BASE_URL'] || 'https://api.cerebras.ai'
      @custom_connection = connection
      @max_retries = max_retries
      @timeout = timeout
      
       if warm_connection
          warm_tcp_connection
        end

    end

    def inspect
      "#<Cerebras::Client api_key=[REDACTED] max_retries=#{@max_retries} timeout=#{@timeout}>"
    end

    def chat
      @chat ||= Chat.new(self)
    end

    def completions
      @completions ||= Completions.new(self)
    end

    def connection
      return @custom_connection if @custom_connection

      @connection ||= Faraday.new(url: @base_url) do |f|
        f.request :retry, {
          max: @max_retries,
          interval: 0.5,
          interval_randomness: 0,
          backoff_factor: 2,
          methods: [:get, :post],
          exceptions: [Faraday::TimeoutError, Faraday::ConnectionFailed],
          retry_statuses: (408..409).to_a + [429] + (500..599).to_a
        }
        f.request :json
        f.response :raise_error
        f.response :json
        f.adapter Faraday.default_adapter
        f.options.timeout = @timeout
      end
    end

    def request(method, path, options = {}, payload = nil, &block)
      path = "/v1#{path}" unless path.start_with?('/v1')
      
      # Handle timeout override
      if options && options[:timeout]
        timeout_val = options[:timeout]
        options = options.dup
        options.delete(:timeout)
        
        response = connection.send(method, path) do |req|
          req.options.timeout = timeout_val
          req.headers['Authorization'] = "Bearer #{@api_key}"
          req.params = options if options && !options[:stream]
          req.body = payload if payload
          
          if block_given? && options && options[:stream] == true
            req.options.on_data = Proc.new do |chunk, _overall_received_bytes|
              block.call(chunk)
            end
          end
        end
      else
        response = connection.send(method, path) do |req|
          req.headers['Authorization'] = "Bearer #{@api_key}"
          req.params = options if options && !options[:stream]
          req.body = payload if payload
          
          if block_given? && options && options[:stream] == true
            req.options.on_data = Proc.new do |chunk, _overall_received_bytes|
              block.call(chunk)
            end
          end
        end
      end
  
      return wrap_response(response.body) unless block_given? && options && options[:stream] == true
      
      nil
    rescue Faraday::TimeoutError, Net::OpenTimeout, Net::ReadTimeout, Faraday::ConnectionFailed

      raise TimeoutError, "Request timed out or connection failed"
    rescue Faraday::ClientError => e
      status = e.response.respond_to?(:status) ? e.response.status : (e.response.is_a?(Hash) ? e.response[:status] : nil)
      case status
      when 429
        raise RateLimitError, "Rate limit exceeded: #{e.message}"
       when 400, 422
         # Debugging: Log the actual response body to see why the request was rejected
         response_body = e.response.body rescue 'Unavailable'
         puts "\n[DEBUG] API 400/422 Response Body: #{response_body}\n"
         raise BadRequestError, "Bad request: #{e.message}. Body: #{response_body}"

      else
        raise APIConnectionError, e.message
      end
    rescue Faraday::Error => e
      raise APIConnectionError, e.message
    end

    def parse_sse(chunk, buffer, state = { current_event_data: nil })
      
      buffer << chunk
      
      while (line_index = buffer.index("\n"))
        line = buffer.slice!(0..line_index)
        stripped = line.strip
        
        if stripped.empty?
          # Event separator encountered
          if state[:current_event_data]
            yield state[:current_event_data].strip if block_given?
            state[:current_event_data] = nil
          end
        elsif stripped.start_with?('data: ')
          state[:current_event_data] ||= ""
          state[:current_event_data] << stripped.sub('data: ', '').strip + "\n"
        end
      end
    end

    private

    def wrap_response(body)
      return body unless body.is_a?(Hash) || body.is_a?(Array)
      
      # Recursive wrap to handle nested structures
      if body.is_a?(Array)
        body.map { |item| wrap_response(item) }
      else
        ResponseWrapper.new(body)
      end
    end

    def warm_tcp_connection

      conn = Faraday.new(url: @base_url) do |f|
        f.adapter Faraday.default_adapter
        f.options.timeout = 1
      end
      
      conn.get('/v1/tcp_warming') do |req|
        req.headers['Authorization'] = "Bearer #{@api_key}"
      end
    rescue StandardError
      # Silently ignore warmup failures
    end
  end
end
