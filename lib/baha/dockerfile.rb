require 'docker'
require 'baha/container_options'
require 'baha/log'
require 'set'
require 'json'
require 'csv'
require 'yaml'

module Baha
  class DockerfileParseError < RuntimeError
    attr_reader :file, :line, :text
    def initialize(file,line, text)
      super("Unable to parse Dockerfile #{file}:#{line}\n#{text}")
      @file = file
      @line = line
      @text = text
    end
  end
  class Dockerfile
    LOG = Baha::Log.for_name("Dockerfile")
    class << self
      def parse(file)
        LOG.info { "Parsing Dockerfile: #{file}" }
        linenum = 0
        image = {
          'run' => [],
          'pre_build' => [],
          'config' => {}
        }
        multiline = []
        f = File.open(file, "r")
        begin
          f.each_line do |rawline|
            linenum = linenum + 1
            line = rawline.chomp.gsub(/^\s*/,'')
            # Skip empty lines
            next if line.empty?
            # Skip comments
            next if line.match(/^#/)
            
            # Buffer multi-lines
            if line.match(/\\$/)
              multiline << line.chop
              next
            end
            multiline << line


            line_to_parse = multiline.join("\n")
            LOG.debug { "Parsing #{linenum}: #{line_to_parse}" }
            unless parse_line(image,line_to_parse)
              raise DockerfileParseError.new(file,linenum, line_to_parse)
            end
            multiline = []
          end
        ensure
          f.close
        end
        image
      end

      def as_array(args)
        begin
          return JSON.parse(args)
        rescue
          return CSV.parse_line(args,{:col_sep => " ", })
        end
      end

      def as_cmd(cmd)
        begin
          return JSON.parse(cmd)
        rescue
          cmd
        end
      end

      def append_attr(image,key,value)
        image[key] = [] unless image.has_key?(key)
        case value
        when Array
          image[key].concat(value)
        else
          image[key].push(value)
        end
      end

      # Resolve environment variables in the string
      def resolve_env(image,value)
        if image['config'].has_key?('env')
          env = image['config']['env']
          env.keys.reduce(value) do |v,k|
            r = Regexp.new("(?<!\\\\)[$](?:\\{#{k}\\}|#{k})")
            v.gsub(r,env[k])
          end
        else
          value
        end
      end

      # Sets the workdir on the image config
      def set_workdir(image,value)
        wd = image['config']['workingdir']
        if wd
          wd = (Pathname.new(wd) + value).to_s
        else
          wd = value
        end
        image['config']['workingdir'] = resolve_env(image,wd)
      end

      def set_env(image,value)
        k,v = value.split(/\s+/,2)
        image['config']['env'] ||= {}
        image['config']['env'][k] = v
      end

      # Parse a line and configure the image
      def parse_line(image,line)
        cmd, args =  line.split(/\s+/,2)
        cmd = cmd.downcase.to_sym
        case cmd
        when :from
          image['parent'] = args
        when :maintainer
          image['maintainer'] = args
        when :expose
          append_attr(image['config'],'exposedports',resolve_env(image,args))
        when :volume
          append_attr(image['config'],'volumes',as_array(resolve_env(image,args)))
        when :entrypoint
          image['config']['entrypoint'] = as_cmd(args)
        when :cmd
          image['config']['cmd'] = as_cmd(args)
        when :run
          image['run'] << as_cmd(args)
        when :user
          image['config']['user'] = resolve_env(image,args)
        when :workdir
          set_workdir(image,args)
        when :env
          set_env(image,resolve_env(image,args))
        else
          return false
        end
        true
      end
    end
  end
end