require 'thor'
require 'baha/builder'
require 'baha/log'
require 'baha/dockerfile'

class Baha::CLI < Thor
  desc "build [options] CONFIG", "Builds all docker images based on the given config"
  long_desc <<-LONGDESC
  Reads the CONFIG file and builds all of the docker images in the order they appear.
  LONGDESC
  option :logfile, {
    :required => false,
    :type => :string,
    :desc => "Log output to LOGFILE. Omit to log to stdout."
  }
  option :debug, {
    :aliases => :d,
    :required => false,
    :type => :boolean,
    :default => false,
    :desc => 'Toggle debug logging. Includes verbose.'
  }
  option :verbose, {
    :aliases => :v,
    :required => false,
    :type => :boolean,
    :default => false,
    :desc => 'Toggle verbose logging'
  }
  option :quiet, {
    :aliases => :q,
    :required => false,
    :type => :boolean,
    :default => false,
    :desc => 'Surpress all logging'
  }
  def build(config)
    quiet = options[:quiet]
    unless quiet
      if options[:logfile].nil? or options[:logfile] == 'STDOUT'
        Baha::Log.logfile = STDOUT 
      else
        Baha::Log.logfile = STDOUT 
      end
      if options[:debug]
        Baha::Log.level = :debug
      elsif options[:verbose]
        Baha::Log.level = :info
      else
        Baha::Log.level = :error
      end
    end
    begin
      builder = Baha::Builder.new(config)
      builder.build!
    rescue Exception => e
      unless quiet
        Baha::Log.for_name("CLI").fatal("Error encountered while building images")
        Baha::Log.for_name("CLI").fatal(e)
      end
      exit 1
    ensure
      Baha::Log.close!
    end
  end
  desc "convert DOCKERFILE", "Converts an existing dockerfile to a Baha-compatible image.yml"
  long_desc <<-LONGDESC
  Reads the given Dockerfile and outputs a Baha-compatible image.yml which can be included or embedded within a CONFIG
  LONGDESC
  option :name, {
    :aliases => :n,
    :required => true,
    :type => :string,
    :desc => "The target image name"
  }
  option :tag, {
    :aliases => :t,
    :required => false,
    :type => :string,
    :default => 'latest',
    :desc => 'The target image tag'
  }
  option :output, {
    :aliases => :o,
    :required => false,
    :type => :string,
    :default => 'STDOUT',
    :desc => 'Target output file'
  }
  def convert(dockerfile)
    file = Pathname.new(dockerfile)
    out = options[:output]
    name = options[:name]
    tag = options[:tag]
    Baha::Log.logfile = STDERR
    Baha::Log.level = :info
    log = Baha::Log.for_name("CLI")
    begin
      if file.exist?
        yaml = Baha::Dockerfile.parse(dockerfile)
        yaml = { 'name' => name, 'tag' => tag }.merge(yaml)
        if out == 'STDOUT'
          puts yaml.to_yaml
        else
          File.open(out,'w') do |f|
            f.write yaml.to_yaml
          end
        end
      else
          log.fatal { "DOCKERFILE #{dockerfile} not found" }
          exit 1
      end
    rescue Exception => e
      log.fatal("Error encountered while building images")
      log.fatal(e)
    end
  end
  desc "version", "Print version and exit"
  def version
    puts "baha " + Baha::VERSION
  end
end
