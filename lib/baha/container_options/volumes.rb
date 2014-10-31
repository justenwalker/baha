require 'baha/container_options/option'
module Baha
  module ContainerOptions
    class Volumes < Option
      def initialize(*args)
        super(:volumes,*args)
      end
      def apply(config)
        unless config.has_key?('Volumes')
          config['Volumes'] = {}
        end
        @value.each do |mount|
          config['Volumes'][mount] = {}
        end
      end
      def validate!
        raise ERROR("should be an array") unless @value.kind_of?(Array)
        @value.each_with_index do |item,index|
          raise ERROR("#{index}: '#{item}' should be a string") unless item.kind_of?(String)
        end
      end
    end
  end
end