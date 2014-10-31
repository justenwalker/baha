require 'spec_helper'
require 'baha/container_options'

describe Baha::ContainerOptions::Option do
  subject(:option) { described_class.new('hostname','value') }
  let(:other) { described_class.new("hostname","value") }
  let(:otherkey)  { described_class.new("user","value") }

  describe '#eql?' do
    it 'is equal to same key' do 
      expect(option.eql?(other)).to eq(true)
    end
    it 'is not equal to other key' do 
      expect(option.eql?(otherkey)).to eq(false)
    end
  end

  describe '#validate!' do
    it 'always validates' do 
      expect(option.validate!).to eq(true)
    end
  end

  describe '#apply' do
    it 'applies its key/value pair' do
      conf = {}
      option.apply(conf)
      expect(conf['Hostname']).to eq('value')
    end
  end

  describe '#inspect' do
    its(:inspect) { should match(/Baha::ContainerOptions::Option<(@[a-z0-9_]+=.*)+>/) }
  end

  it 'has a sym key' do 
    expect(option.key).to be_a(Symbol)
  end

  it 'has a value' do 
    expect(option.value).to eq('value')
  end
end