module Cerebras
  class ResponseWrapper
    def initialize(hash)
      @data = hash
    end

    def method_missing(method_name, *args, &block)
      key = method_name.to_s
      if @data.key?(key) || @data.key?(key.to_sym)
        wrap_value(@data[key] || @data[key.to_sym])
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      @data.key?(method_name.to_s) || @data.key?(method_name.to_sym) || super
    end

    def to_h
      @data
    end

    def inspect
      "#<Cerebras::ResponseWrapper #{@data.inspect}>"
    end

    private

    def wrap_value(value)
      case value
      when Hash
        ResponseWrapper.new(value)
      when Array
        value.map { |v| wrap_value(v) }
      else
        value
      end
    end
  end
end
