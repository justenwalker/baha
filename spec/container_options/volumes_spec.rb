require 'spec_helper'
require 'baha/container_options'

describe Baha::ContainerOptions::Volumes do
  subject(:option) { described_class.new(["/mnt/data","/mnt/logs"]) }
  
  describe 'validate!' do
    subject(:invalid) { described_class.new("value") }
    it 'validates on hash values' do 
      expect { option.validate! }.to_not raise_error
    end
    it 'does not validate non-hash values' do 
      expect { invalid.validate! }.to raise_error(Baha::ContainerOptions::InvalidOptionError)
    end
  end

  describe 'apply' do
    let(:expected) { { 'Volumes' => {'/mnt/data' => {}, '/mnt/logs' => {} } } }
    it 'applies volume config' do
      conf = {}
      option.apply(conf)
      expect(conf).to eq(expected)
    end
  end
end