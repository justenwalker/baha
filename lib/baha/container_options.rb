require 'baha/container_options/cmd'
require 'baha/container_options/entrypoint'
require 'baha/container_options/env'
require 'baha/container_options/exposed_ports'
require 'baha/container_options/invalid_option_error'
require 'baha/container_options/option'
require 'baha/container_options/volumes'
module Baha
  module ContainerOptions
    def self.parse_options(options)
      if options
        Hash[options.map { |k,v| opt = self.parse_option(k,v)
          [opt.key,opt] }]
      else
        {}
      end
    end
    def self.parse_option(key,value)
      k = key.to_sym.downcase
      option = case k
      when :volumes
        Volumes.new(value)
      when :env
        Env.new(value)
      when :cmd 
        Cmd.new(value)
      when :entrypoint
        Entrypoint.new(value)
      when :exposedports
        ExposedPorts.new(value)
      else
        Option.new(key,value)
      end
      option.validate!
      option
    end
  end
end