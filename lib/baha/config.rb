require 'yaml'
require 'pathname'
require 'baha/log'
require 'baha/dockerfile'
require 'baha/refinements'

module Baha
class Config
  using Baha::Refinements
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
      LOG.debug { "Loading file #{filepath.expand_path}"}
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
    config_workspace

    # Defaults
    defaults = config['defaults'] || {}
    raise ArgumentError.new("Expected Hash for defaults") unless defaults.is_a?(Hash)
    @defaults = {}
    DEFAULTS.keys.each do |k|
      @defaults[k] = defaults[k] || DEFAULTS[k]
    end
    @secure = false
    @options = {}
    init_security if ENV.has_key?('DOCKER_CERT_PATH') || config.has_key?('ssl')
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
      elsif image.has_key?('dockerfile')
        path = Pathname.new(image['dockerfile'])
        file = resolve_file(path)
        if file
          dockerfile = Baha::Dockerfile.parse(file)
          dockerfile['name'] = image['name']
          dockerfile['tag'] = image['tag']
          yield Baha::Image.new(self,dockerfile)
        else
          LOG.error { "Unable to find dockerfile: #{path}"}
          next
        end
      else
        yield Baha::Image.new(self,image)
      end
    end
  end

  def workspace_for(image)
    if @ws_mount
      @ws_mount + image
    else
      @workspace + image
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
    set_docker_url
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

  private

  def config_workspace
    def nonnil(*args)
      args.find{ |x| not x.nil? }
    end

    if ENV['BAHA_MOUNT']
      @ws_mount  = Pathname.new(ENV['BAHA_WORKSPACE_MOUNT'])
      @cfg_mount = Pathname.new(ENV['BAHA_MOUNT'])
      @configdir = Pathname.new('/baha')
      @workspace = Pathname.new('/workspace')
    else
      cfgdir = @config['configdir'] || Pathname.pwd.to_s
      @configdir = Pathname.new(cfgdir)

      work = @config['workspace'] || (@configdir + 'workspace').to_s
      @workspace = Pathname.new(work)
    end
  end

  def set_docker_url
    if @config.has_key?('docker_url')
      Docker.url = @config['docker_url']
    end
    if @secure
      Docker.url = Docker.url.gsub(/^tcp:/,'https:')
    end
  end

  def ssl_from_env
    ssl_options = {}
    cert_path = Pathname.new(ENV['DOCKER_CERT_PATH'])
    ssl_options[:ssl_verify_peer] = (ENV['DOCKER_TLS_VERIFY'] == '1')
    ssl_options[:client_cert] = (cert_path + 'cert.pem').expand_path.to_s
    ssl_options[:client_key] = (cert_path + 'key.pem').expand_path.to_s
    ssl_options[:ssl_ca_file] = (cert_path + 'ca.pem').expand_path.to_s
    ssl_options
  end

  def ssl_from_config
    ssl = @config['ssl']
    ssl_options = {}
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
    ssl_options
  end

  def init_security
    @secure = true
    cert_path = ''
    ssl = { }
    if ENV['DOCKER_CERT_PATH']
      ssl = ssl_from_env
    elsif @config.has_key?('ssl')
      ssl = ssl_from_config
    end
    @options.merge!(ssl)
  end

end
end
