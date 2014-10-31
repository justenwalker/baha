module Baha
  module ContainerOptions
    class InvalidOptionError < RuntimeError
      attr_reader :key
      attr_reader :value
      attr_reader :reason
      def initialize(key,value,reason)
        super("Unable to validate option: #{key}. '#{value}' #{reason}")
        @key = key
        @value = value
        @reason = reason
      end
    end
  end
end