require 'yaml'
require 'pathname'
require 'baha/log'

class Baha::Config
  DEFAULTS = {
    :parent => 'ubuntu:14.04.1',
    :bind   => '/.baha',
    :command => ['/bin/bash','./init.sh'],
    :repository => nil,
    :maintainer => nil,
    :timeout => 1200
  }
  LOG = Baha::Log.for_name("Config")
  class << self
    def load(file)
      LOG.debug { "Loading file #{file}"}
      filepath = Pathname.new(file)
      raise ArgumentError.new("Cannot read config file #{file}") unless filepath.readable?
      config = YAML.load_file(filepath)
      config['configdir'] ||= filepath.dirname
      Baha::Config.new(config)
    end
  end

  attr_reader :configdir, :workspace, :secure, :options
  attr_reader :defaults

  def initialize(config)
    @config = config
    
    # Defaults
    defaults = config['defaults'] || {}
    raise ArgumentError.new("Expected Hash for defaults") unless defaults.is_a?(Hash)
    @defaults = {}
    DEFAULTS.keys.each do |k|
      @defaults[k] = defaults[k] || defaults[k.to_s] || DEFAULTS[k]
    end

    @configdir = Pathname.new(config['configdir'] || Pathname.pwd)
    @workspace = Pathname.new(config['workspace'] || @configdir + 'workspace')
    @secure = false
    @options = {}
    init_security if ENV.has_key?('DOCKER_CERT_PATH') || config.has_key?('ssl')
  end

  def init_security
    @secure = true
    cert_path = ''
    ssl_options = { }
    if ENV['DOCKER_CERT_PATH']
      cert_path = Pathname.new(ENV['DOCKER_CERT_PATH'])
      ssl_options[:ssl_verify_peer] = (ENV['DOCKER_TLS_VERIFY'] == '1')
      ssl_options[:client_cert] = (cert_path + 'cert.pem').expand_path.to_s
      ssl_options[:client_key] = (cert_path + 'key.pem').expand_path.to_s
      ssl_options[:ssl_ca_file] = (cert_path + 'ca.pem').expand_path.to_s
    elsif @config.has_key?('ssl')
      ssl = @config['ssl']
      ssl_options[:ssl_verify_peer] = ssl['verify'] || false
      if ssl.has_key?('cert_path')
        cert_path = Pathname.new(ssl['cert_path'])
        ssl_options[:client_cert] = (cert_path + 'cert.pem').expand_path.to_s
        ssl_options[:client_key] = (cert_path + 'key.pem').expand_path.to_s
        ssl_options[:ssl_ca_file] = (cert_path + 'ca.pem').expand_path.to_s
      else
        ssl_options[:client_cert] = ssl['cert']
        ssl_options[:client_key] = ssl['key']
        ssl_options[:ssl_ca_file] = ssl['ca']
      end
    end
    @options.merge!(ssl_options)
  end

  def each_image
    return unless @config.has_key?('images')
    @config['images'].each do |image|
      if image.has_key?('include')
        path = Pathname.new(image['include'])
        file = resolve_file(path)
        if file
          yml = YAML.load_file(file)
          yield Baha::Image.new(self,yml)
        else
          LOG.error { "Unable to find image include: #{path}"}
          next
        end
      else
        yield Baha::Image.new(self,image)
      end
    end
  end

  def resolve_file(file)
    filepath = Pathname.new(file)
    LOG.debug { "resolve_file(#{file})" }
    paths = [ 
      filepath,            # 0. Absolute path
      @workspace + file,   # 1. Workspace
      @configdir + file,   # 2. Config
      Pathname.pwd + file  # 3. Current directory
    ]
    paths.reduce(nil) do |result,path|
      if result.nil?
        if path.exist?
          result = path
          LOG.debug("found file at: #{path}")
        else
          LOG.debug("did not find file at: #{path}")
        end
      end  
      result
    end
  end

  # Initialize Docker Client
  def init_docker!
    Docker.options = @options
    if @config.has_key?('docker_url')
      url = @config['docker_url']
      Docker.url = url
    end
    if @secure
      Docker.url = Docker.url.gsub(/^tcp:/,'https:')
    end
    LOG.debug { "Docker URL: #{Docker.url}"}
    LOG.debug { "Docker Options: #{Docker.options.inspect}"}
    Docker.validate_version!
  end

  def inspect
    <<-eos.gsub(/\n?\s{2,}/,'')
    #{self.class.name}<
      @config=#{@config.inspect},
      @configdir=#{@configdir},
      @workspace=#{@workspace},
      @defaults=#{@defaults.inspect},
      @secure=#{@secure},
      @options=#{@options.inspect}
    >
    eos
  end
end