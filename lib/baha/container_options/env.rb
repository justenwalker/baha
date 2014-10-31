require 'baha/container_options/option'
module Baha
  module ContainerOptions
    class Env < Option
      def initialize(*args)
        super(:env,*args)
      end
      def apply(config)
        unless config.has_key?('Env')
          config['Env'] = []
        end
        @value.each_pair do |k,v|
          config['Env'] << "#{k}=#{v}"
        end
      end
      def validate!
        raise ERROR("should be a hash") unless @value.kind_of?(Hash)
      end
    end
  end
end