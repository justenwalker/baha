require 'baha/container_options/invalid_option_error'
require 'baha/container_options/option'
module Baha
  module ContainerOptions    
    class ExposedPorts < Option
      def initialize(*args)
        super(:exposedports,*args)
      end
      def apply(config)
        unless config.has_key?('ExposedPorts')
          config['ExposedPorts'] = {}
        end
        @value.each do |port|
          case port
            when Fixnum
              config['ExposedPorts']["#{port}/tcp"] = {}
            when String
              config['ExposedPorts'][port] = {}
          end
        end
      end

      def validate!
        raise ERROR("should be an array") unless @value.kind_of?(Array)
        @value.each_with_index do |item,index|
          if item.kind_of?(String)
            unless /(\d+)\/(tcp|udp)/ =~ item
              raise ERROR("#{index}: '#{item}' should be in the form 8080/tcp")
            end
          end
        end
      end
    end
  end
end
