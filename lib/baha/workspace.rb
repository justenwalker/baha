require 'docker'
module Baha
  class Workspace

    attr_reader :directory

    def initialize(options)
      @options = {}
      @options.merge!(options)
      @directory = @options['directory'] || Dir.pwd
    end
  end
end