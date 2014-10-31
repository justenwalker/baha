# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'baha/version'

Gem::Specification.new do |spec|
  spec.name          = "baha"
  spec.version       = Baha::VERSION
  spec.authors       = ["Justen Walker"]
  spec.email         = ["justen.walker+github@gmail.com"]
  spec.summary       = %q{Baha - A tool for describing image builds for Docker}
  spec.description   = %q{Baha - A tool for describing image builds for Docker}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'thor', '~> 0.19.1'
  spec.add_dependency 'docker-api', '~> 1.14.0'
  spec.add_dependency 'json', '~> 1.8.1'

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.1.0'
  spec.add_development_dependency 'rspec-mocks', '~> 3.1.3'
  spec.add_development_dependency 'rspec-its', '~> 1.1.0'
  spec.add_development_dependency 'simplecov', '~> 0.9.1'
end
