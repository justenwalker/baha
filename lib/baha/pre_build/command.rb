require 'baha/pre_build'
require 'open3'

module Baha
class PreBuild::Module::Command
  LOG = Baha::Log.for_name("Module::Command")

  def self.execute(mod)
    LOG.debug("execute(#{mod.args.inspect})")
    command = mod.args['command']
    creates = mod.args['creates']
    onlyif  = mod.args['only_if']

    cwd = mod.image.workspace.expand_path

    if creates
      filepath = cwd + creates
      LOG.debug { "Checking if file exists #{filepath}"}
      if filepath.exist?
        LOG.info("#{creates} exists - skipping command")
        return
      end
    end

    if onlyif
      exit_status = 0
      LOG.info { "Running test [onlyif] #{onlyif.inspect}" }
      Open3.popen2e(onlyif,:chdir=>cwd.to_s) do |stdin, oe, wait_thr|
        oe.each do |line|
          LOG.debug { "++ " + line }
        end
        exit_status = wait_thr.value # Process::Status object returned.
      end
      unless exit_status.success?
        LOG.debug { "onlyif did not exist successfully - skipping command" }
        return
      end
    end

    LOG.info { "Running command #{command.inspect}" }
    Open3.popen2e(command,:chdir=>cwd.to_s) do |stdin, oe, wait_thr|
      oe.each do |line|
        LOG.debug { "++ " + line.chomp }
      end
    end

  end
end
end
Baha::PreBuild::Module.register(:command) do |mod|
  Baha::PreBuild::Module::Command.execute(mod)
end
