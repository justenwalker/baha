module Baha::PreBuild
  LOG = Baha::Log.for_name(self.class.name)
  class ModuleNotFoundError < StandardError
    attr_reader :task
    def initialize(task)
      super("Could not find a module that could parse #{task.inspect}")
      @task = task
    end
  end
  class Module
    class << self
      @@modules = []

      def register(name, options = {}, &block)
        LOG.debug { "register module #{name} (#{options.inspect})" }
        @@modules << name
        name = name.intern
        send(:define_singleton_method,"module_#{name}",&block)
      end

      def execute(task)
        @@modules.each do |mod|
        if task.has_key?(mod.to_s)
            LOG.info { "Executing module #{mod}" }
            method = "module_#{mod}".intern
            self.send(method, Module.new(task))
            return
          end
        end
        raise ModuleNotFoundError.new(task)
      end
    end

    attr_reader :config, :image, :args

    def initialize(task)
      @config = task.delete(:config)
      @image = task.delete(:image)
      @args = task
    end

  end
end

require 'baha/pre_build/download'
require 'baha/pre_build/template'
require 'baha/pre_build/command'