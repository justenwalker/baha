require 'spec_helper'
require 'baha/container_options'

describe Baha::ContainerOptions::Env do
  subject(:option) { described_class.new({'KEY' => 'value'}) }

  describe 'validate!' do
    let(:invalid) { described_class.new('value') }

    it 'validates on hash values' do 
      expect { option.validate! }.to_not raise_error
    end
    it 'does not validate non-hash values' do 
      expect { invalid.validate! }.to raise_error(Baha::ContainerOptions::InvalidOptionError)
    end
  end

  describe 'apply' do
    let(:expected) { { 'Env' => ['KEY=value'] } }
    it 'applies its key=value pair' do
      conf = {}
      option.apply(conf)
      expect(conf).to eq(expected)
    end
  end
end