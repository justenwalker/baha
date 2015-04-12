require 'docker'
module Baha
  class Workspace

    attr_reader :directory

    def initialize(options)
      @options = {}
      @options.merge!(options)
      @directory = @options['directory'] || Dir.pwd
      @mount_dir = @options['mount_dir'] || @directory
      @image = @options['image']
    end

    def +(file)
      Pathname.new(@mount_dir) + @image + file
    end

    def directory
      Pathname.new(@workspace)
    end
  end
end