require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
end

require 'bundler/setup'
Bundler.setup

require 'baha'
require 'helpers/docker_helpers.rb'
require 'rspec/its'
require 'rspec/mocks'
require 'pathname'
require 'stringio'

def fixture_path
  Pathname.new(File.expand_path(File.join(__FILE__, '..', 'fixtures')))
end
def fixture(filename)
  file = fixture_path + filename
  raise ArgumentError.new("File #{filename} could not be found") unless file.exist?
  file
end

RSpec.configure do |config|
 # config.color_enabled = true
  config.order = "random"

  config.include DockerHelpers

  # Forbid old 'should' syntax
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:each) do
    Baha::Log.logfile = StringIO.new
  end
end

RSpec::Matchers.define :pathname_matching do |expected|
  match do |actual|
    case expected
    when Regexp
      expected.match(actual.to_s) != nil
    else
      expected == actual
    end
  end
end