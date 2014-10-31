require 'docker'
require 'baha/container_options'
require 'baha/log'
require 'set'

module Baha
  class ImageNotFoundError < RuntimeError
    attr_reader :image
    def initialize(image)
      super("Unable to locate image : #{image[:name]}:#{image[:tag]}")
      @image = image
    end
  end
  class Image
    LOG = Baha::Log.for_name("Image")
    class << self
        # Parses an image name
        def parse_name(image)
          m = /(?:([a-z0-9\-._\/]+))(?::([a-zA-Z0-9\-._]+))?/.match(image)
          unless m
            raise ArgumentError.new("Unable to parse image name #{image}")
          end
          tag  = m.captures[1]
          tag  ||= 'latest'
          imagename = m.captures[0]
          m2 = /(?:(.+)\/)?(.+)/.match(imagename)
          ns = m2.captures[0]
          name = m2.captures[1]
          {
            :ns    => ns,
            :name  => name,
            :tag   => tag
          }
        end

        def parse_with_default(image,repository)
          i = parse_name(image)
          unless i[:ns]
            i[:ns] = repository
          end
          i
        end

        def get_image!(image)
          LOG.debug { "get_image!(#{image.inspect})" }
          tag = image[:tag] || 'latest'
          repo = "#{image[:ns]}/#{image[:name]}"
          img = [ 
            lambda { Docker::Image.get("#{image[:name]}:#{image[:tag]}") },
            lambda { Docker::Image.create('fromImage'=> image[:name], 'tag' => tag) },
            lambda { Docker::Image.create('fromImage' => repo, 'tag' => tag) }
          ].reduce(nil) do |result,block|
            unless result
              begin
                result = block.call
                result = Docker::Image.get(result.id)
              rescue
                result = nil
              end
            end
            result
          end
          raise Baha::ImageNotFoundError.new(image) unless img
          img
        end

    end
    attr_reader :parent, :image, :maintainer, :options, :pre_build, :bind, :command, :timeout, :workspace, :name, :tags

    def initialize(config,image)
      @parent = Baha::Image.parse_with_default(image['parent'] || config.defaults[:parent], config.defaults[:repository])
      @image  = Baha::Image.parse_with_default(image['name'], config.defaults[:repository])
      @image[:tag] = image['tag'] if image.has_key?('tag')
      @maintainer = image['maintainer'] || config.defaults[:maintainer]
      @options = Baha::ContainerOptions::parse_options(image['config'])
      @pre_build = image['pre_build']
      @bind = image['bind'] || config.defaults[:bind]
      @command = image['command'] || config.defaults[:command]
      @timeout = image['timeout'] || config.defaults[:timeout]
      @workspace = config.workspace + (image['workspace'] || @image[:name])
      @name = @image[:name]
      @tags = Set.new [
        "#{@image[:name]}:#{@image[:tag]}",
        "#{@image[:name]}:latest"
      ]
      if @image[:ns]
        @tags << "#{@image[:ns]}/#{@image[:name]}:#{@image[:tag]}"
        @tags << "#{@image[:ns]}/#{@image[:name]}:latest"
      end
    end

    def env
      {
        :parent => @parent,
        :maintainer => @maintainer,
        :bind => @bind,
        :name => @image[:name],
        :tag  => @image[:tag],
        :workspace => @workspace.expand_path.to_s
      }
    end

    def parent_id
      parent = Baha::Image.get_image!(@parent)
      parent.id
    end

    def commit_config
      @options.values.reduce({}) do |memo,option|
        option.apply(memo)
        memo
      end
    end

    # Checks if the image needs updating
    # 1. If it's parent image has changed
    # 2. If the desired tag is not found
    # Will raise Baha::ImageNotFoundError if the parent image can not be found
    def needs_update?
      LOG.debug { "needs_update?(#{@image.inspect})" }
      parent = Baha::Image.get_image!(@parent)
      LOG.debug { "got parent: #{parent.inspect}" }
      begin
        image = Baha::Image.get_image!(@image)
        LOG.debug { "got image: #{image.inspect}" }
        parent_id = image.info['Parent']
        this_tags = image.history[0]["Tags"]
        local_tag = "#{@image[:name]}:#{@image[:tag]}"
        remote_tag = "#{@image[:ns]}/#{local_tag}"
        LOG.debug { "current parent id = #{parent_id}" }
        LOG.debug { "current image tags = #{parent_id}" }
        LOG.debug { "current parent id = #{parent_id}" }
        parent_id != parent.id or not ( this_tags.include?(local_tag) or this_tags.include?(remote_tag) )
      rescue
        true
      end
    end

    def inspect
      <<-eos.gsub(/\n?\s{2,}/,'')
      #{self.class.name}<
        @parent=#{@parent.inspect},
        @image=#{@image.inspect},
        @maintainer=#{@maintainer},
        @options=#{@options.inspect},
        @pre_build=#{@pre_build.inspect},
        @bind=#{@bind},
        @command=#{@command.inspect},
        @timeout=#{@timeout}
      >
      eos
    end
  end
end