require 'baha/container_options/invalid_option_error'
require 'baha/container_options/option'
module Baha
  module ContainerOptions 
    class Cmd < Option

      def self.split_command(cmd)
        require 'csv'
        CSV.parse_line(cmd,{:col_sep => ' ', :skip_blanks => true, :quote_char => '"'})
      end

      def initialize(*args)
        if args.length < 2 then
          @conf = 'Cmd'
          super('Cmd',*args)
        else
          @conf = args[0]
          super(*args)
        end
      end
      def apply(config)
        if @value.kind_of?(Array)
          config[@conf] = @value
        else
          config[@conf] = Cmd::split_command(@value)
        end
      end
      def validate!
        raise ERROR("should be an array or string") unless @value.kind_of?(Array) or @value.kind_of?(String)
      end
    end
  end
end