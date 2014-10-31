require 'baha/config'
require 'baha/image'
require 'baha/log'
require 'baha/pre_build'
require 'fileutils'

class Baha::Builder
  LOG = Baha::Log.for_name("Builder")

  class BuildError < RuntimeError
    attr_reader :image, :status
    def initialize(status,image)
      super("Unable to build image : #{image.name} -- Status: #{status.inspect}")
      @image = image
      @status = status
    end
  end

  attr_reader :config

  def initialize(config)
    @config = case config
    when Baha::Config
      config
    else
      Baha::Config.load(config.to_s)
    end
  end

  def build!
    LOG.info("Building Images")
    LOG.debug { "Config: #{@config.inspect}" }
    LOG.debug { "Initializing Docker" }
    @config.init_docker!

    @config.each_image do |image|
      build_log = Baha::Log.for_name("Builder [#{image.name}]")
      unless image.needs_update?
        build_log.info { "Skipped image #{image.name} - No update needed" }
        next
      end
      
      ## Prepare Workspace
      workspace = Pathname.new(@config.workspace) + image.name
      unless workspace.exist?
        build_log.debug { "Creating Workspace: #{workspace}" }
        FileUtils.mkdir_p workspace.to_s
      end

      ## Pre-Build tasks
      build_log.info { "Building #{image.name}" }
      if image.pre_build
        build_log.debug { "Preparing workspace for #{image.name}" }
        image.pre_build.each do |task|
          build_log.debug { "execute task: #{task.inspect}" }
          Baha::PreBuild::Module.execute(task.merge({ :config => @config, :image => image }))
        end
      end

      ## Build Image
      container_config = {
        'Image'       => image.parent_id,
        'Cmd'         => image.command,
        'Workingdir'  => image.bind
      }
      build_log.debug { "Creating container for #{image.name} => #{container_config.inspect}" }
      container = Docker::Container.create(container_config)
      build_log.debug { "Created container #{container.id} "}

      build_log.debug { "Running container for #{image.name}" }
      container.start({
        'Binds' => "#{image.workspace.expand_path}:#{image.bind}"
      })

      begin
        ## Stream logs
        container.streaming_logs({'stdout' => true, 'stderr' => true, 'follow' => true, 'timestamps' => false }) do |out,msg|
          case out
          when :stdout
            build_log.info { "++ #{msg.chomp}" }
          when :stderr
            build_log.warn { "++ #{msg.chomp}" }        
          end
        end
        ## Wait for finish
        build_log.debug { "Waiting #{image.timeout} seconds for container #{container.id} to finish building" }
        status = container.wait(image.timeout)
      rescue Exception => e
        build_log.error { "Error building image #{image.name}" }
        build_log.error { e }
        build_log.info { "Removing container #{container.id}" }
        container.stop
        container.remove
        raise BuildError.new("Interrupted",image)
      end

      if status['StatusCode'] != 0
        build_log.error { "Error building image #{image.name}" }
        build_log.info { "Removing container #{container.id}" }
        container.remove
        raise BuildError.new(status,image)
      end

      ## Commit Image
      build_log.debug { "Committing Container #{container.id}" }
      build_log.debug { "Run Config: #{image.commit_config}" }
      build_image = container.commit({'run'=>image.commit_config})

      build_log.info { "New Image created: #{build_image.id}"}
      build_image = Docker::Image.get(build_image.id)

      image.tags.each do |tag|
        build_log.debug { "Tagging as #{tag}"}
        t = tag.split(/:/)
        build_image.tag(:repo => t[0], :tag => t[1])
      end

      ## Cleanup container
      container.remove
    end
  end

  def inspect
    <<-eos.gsub(/\n?\s{2,}/,'')
    #{self.class.name}<
      @config=#{@config.inspect}
    >
    eos
  end
end