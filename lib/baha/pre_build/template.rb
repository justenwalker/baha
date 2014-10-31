require 'baha/pre_build'
require 'erb'
require 'ostruct'

class Baha::PreBuild::Module::Template
  LOG = Baha::Log.for_name("Module::Template")

  class ErbBinding < OpenStruct
      def initialize(hash,config)
        super(hash)
        @config = config
      end
      def get_binding
        binding()
      end
      def render(file)
        rfile = @config.resolve_file(file) || @config.resolve_file(File.join(name,file))
        if rfile
          ERB.new(File.read(rfile),0,'-').result(binding)
        else
          raise ArgumentError.new("Template unable to render #{file}: not found")
        end
      end
  end

  def self.execute(mod)   
    LOG.debug("template(#{mod.args.inspect})")

    template = mod.args['template']
    src = mod.config.resolve_file(mod.args['template'])
    dest = mod.image.workspace + mod.args['dest']
    raise ArgumentError.new("Unable to find template file #{template}") if src.nil?  
    LOG.info { "Loading template #{src}" }
    template_str = File.read(src)
    erb = ERB.new(template_str,0,'-')
    environment = mod.image.env
    environment.merge!(Hash[mod.args.map{|k,v| [k.to_sym, v]}])
    LOG.debug { "template environment: #{environment.inspect}" }
    LOG.info { "Writing to #{dest}" }
    File.open(dest,"w") do |f|
      f.write(erb.result(ErbBinding.new(environment,mod.config).get_binding))
    end
  end
end

Baha::PreBuild::Module.register(:template) do |mod|
  Baha::PreBuild::Module::Template.execute(mod)
end