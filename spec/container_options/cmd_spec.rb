require 'spec_helper'
require 'baha/container_options'

describe Baha::ContainerOptions::Cmd do
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
    let(:expected) { { 'Cmd' => ["/bin/bash","-l"] } }
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
  describe 'split_command' do
    it 'splits on spaces' do
      expect(described_class.split_command('/bin/bash -l')).to eq(['/bin/bash','-l'])
    end
    it 'splits on multiple spaces' do
      expect(described_class.split_command('/bin/bash     -l')).to eq(['/bin/bash','-l'])
    end
    it 'does not split quotes' do
      expect(described_class.split_command('/bin/bash -l echo "Hello, World!"')).to eq(['/bin/bash','-l','echo','Hello, World!'])
    end
    it 'does not squash escaped quotes' do
      expect(described_class.split_command('/bin/bash -l echo "Hello, ""World!"')).to eq(['/bin/bash','-l','echo','Hello, "World!'])
    end
  end
end