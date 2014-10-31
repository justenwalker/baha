require 'thor'
require 'baha/builder'
require 'baha/log'

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
  desc "version", "Print version and exit"
  def version
    puts "baha " + Baha::VERSION
  end
end
