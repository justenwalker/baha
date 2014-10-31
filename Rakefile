require "bundler/gem_tasks"
require 'rake/clean'
require 'rspec/core/rake_task'

require 'rake/clean'
CLEAN.include('pkg/', 'example/workspace')
CLOBBER.include('Gemfile.lock')

RSpec::Core::RakeTask.new('spec')

desc "Run example baha build"
task :example do
  require 'pathname'
  exampleyml = (Pathname.pwd + 'example' + 'example.yml')
  puts "Running: baha build -d #{exampleyml}"
  sh('baha', 'build', '-d', exampleyml.to_s)
end

task :default do
  sh %{rake -T}
end
