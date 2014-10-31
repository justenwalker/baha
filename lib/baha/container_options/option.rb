require 'baha/container_options/invalid_option_error'
module Baha
  module ContainerOptions
    class Option
      KEYS = {
        :cmd => 'Cmd',
        :cpushares => 'CpuShares',
        :cpuset => 'Cpuset',
        :domainname => 'Domainname',
        :entrypoint => 'Entrypoint',
        :env => 'Env',
        :exposedports => 'ExposedPorts',
        :hostname => 'Hostname',
        :image => 'Image',
        :memory => 'Memory',
        :memoryswap => 'MemorySwap',
        :networkdisabled => 'NetworkDisabled',
        :user => 'User',
        :volumes => 'Volumes',
        :workingdir => 'WorkingDir',
      }

      attr_reader :key
      attr_reader :config_key
      attr_reader :value

      def initialize(*args)
        k,@value = args
        raise ArgumentError, "Cannot understand option key '#{k}'" unless k.respond_to?(:to_sym)
        @key = k.to_sym.downcase
        raise ERROR("Option with key '#{@key}' is not found. Expecting #{KEYS.keys.inspect}") unless KEYS.has_key?(@key)
        @config_key = KEYS[@key]
      end
      
      def eql?(other)
        @key == other.key and @value == other.value
      end
      
      # Apply this option to the container's config hash
      def apply(config)
        config[@config_key] = @value
      end

      # Validate the option's value
      def validate!
        KEYS.has_key?(@key)
      end

      def inspect
        "#{self.class.name}<@key=#{@key.inspect},@value=#{@value.inspect}>"
      end

      private 
      def ERROR(reason)
        InvalidOptionError.new(@key,@value,reason)
      end
    end
  end
end