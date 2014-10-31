require 'baha/pre_build'
require 'open-uri'

class Baha::PreBuild::Module::Download
  LOG = Baha::Log.for_name("Module::Download")

  def self.execute(mod)
    LOG.debug("execute(#{mod.args.inspect})")

    filename = mod.image.workspace + mod.args['file']
    url = mod.args['download']
    overwrite = mod.args['overwrite'] || false
    if Pathname.new(filename).exist? and not overwrite
      LOG.info("#{filename} already exists")
    else
      LOG.info("Download #{url} -> #{filename}")
      File.open(filename, "w") do |saved_file|
        open(url, "rb") do |read_file|
          saved_file.write(read_file.read)
        end
      end
    end
  end
end

Baha::PreBuild::Module.register(:download) do |mod|
  Baha::PreBuild::Module::Download.execute(mod)
end