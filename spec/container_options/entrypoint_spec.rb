require 'spec_helper'
require 'baha/container_options'

describe Baha::ContainerOptions::Entrypoint do
  subject(:option) { described_class.new(["/bin/bash","-l"]) }
  subject(:option2) { described_class.new('/bin/bash -l') }
  describe 'validate!' do
    subject(:invalid) { described_class.new(123) }
    it 'validates on array values' do 
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
    let(:expected) { { 'Entrypoint' => ["/bin/bash","-l"] } }
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