require 'spec_helper'
require 'baha/container_options'

describe Baha::ContainerOptions::ExposedPorts do
  subject(:option) { described_class.new([8080]) }
  subject(:option2) { described_class.new(['8080/tcp']) }
  describe 'validate!' do
    subject(:invalid) { described_class.new(['wtf']) }
    it 'validates on num values' do 
      expect { option.validate! }.to_not raise_error
    end
    it 'validates on string values' do 
      expect { option2.validate! }.to_not raise_error
    end
    it 'does not validate other values' do 
      expect { invalid.validate! }.to raise_error(Baha::ContainerOptions::InvalidOptionError)
    end
  end
  describe 'apply' do
    let(:expected) { { 'ExposedPorts' => { '8080/tcp' => {} } } }
    it 'applies array command' do
      conf = {}
      option.apply(conf)
      expect(conf).to eq(expected)
    end
    it 'applies string command' do
      conf = {}
      option2.apply(conf)
      expect(conf).to eq(expected)
    end
  end
end