require 'baha/container_options/cmd'
module Baha
  module ContainerOptions 
    class Entrypoint < Cmd
      def initialize(*args)
        super('Entrypoint',*args)
      end
    end
  end
end