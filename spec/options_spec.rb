require 'spec_helper'
require 'baha/container_options'

describe Baha::ContainerOptions do
  describe 'parse_option' do
    it 'parses Cmd' do
      expect(Baha::ContainerOptions::parse_option(:cmd,'/bin/bash -l')).to be_a(Baha::ContainerOptions::Cmd)
    end
    it 'parses Entrypoint' do
      expect(Baha::ContainerOptions::parse_option(:entrypoint,['/bin/bash','-l'])).to be_a(Baha::ContainerOptions::Entrypoint)
    end
    it 'parses Env' do
      expect(Baha::ContainerOptions::parse_option(:env,{'key' => 'value'})).to be_a(Baha::ContainerOptions::Env)
    end
    it 'parses raw option' do
      expect(Baha::ContainerOptions::parse_option(:hostname,'host.local')).to be_a(Baha::ContainerOptions::Option)
    end
    it 'parses Volumes' do
      expect(Baha::ContainerOptions::parse_option(:volumes,['/mnt/media'])).to be_a(Baha::ContainerOptions::Volumes)
    end
    it 'parses ExposedPorts' do
      expect(Baha::ContainerOptions::parse_option(:exposedports,[8080,'8443/tcp'])).to be_a(Baha::ContainerOptions::ExposedPorts)
    end
    it 'validates values' do
      expect{ Baha::ContainerOptions::parse_option(:exposedports,:notavalidvalue) }.to raise_error(Baha::ContainerOptions::InvalidOptionError)
    end
  end
  describe 'parse_options' do
    it 'parses all options' do
      expected = {
        :entrypoint => Baha::ContainerOptions::Entrypoint.new('/bin/bash'),
        :cmd => Baha::ContainerOptions::Cmd.new('-l'),
        :volumes => Baha::ContainerOptions::Volumes.new(['/mnt/data']),
        :env => Baha::ContainerOptions::Env.new({'ENVKEY' => 'Hello'}),
        :exposedports => Baha::ContainerOptions::ExposedPorts.new([8080,'8443/tcp']),
        :hostname => Baha::ContainerOptions::Option.new('hostname','localhost.localdomain')
      }
      actual = Baha::ContainerOptions::parse_options({
        'entrypoint' => '/bin/bash',
        'cmd' => '-l',
        'volumes' => ['/mnt/data'],
        'env' => {'ENVKEY' => 'Hello'},
        'exposedports' => [ 8080, '8443/tcp' ],
        'hostname' => 'localhost.localdomain'
      })
      expect(actual).to eql(expected)
    end
    it 'returns empty map on nil options' do
      expect(Baha::ContainerOptions::parse_options(nil)).to eql({})
    end
  end
end