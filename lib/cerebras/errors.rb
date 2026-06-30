module Cerebras
  class APIConnectionError < StandardError; end
  class TimeoutError < APIConnectionError; end
  class RateLimitError < APIConnectionError; end
  class BadRequestError < StandardError; end
end
