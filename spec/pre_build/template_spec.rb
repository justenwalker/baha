require 'spec_helper'

require 'pathname'
require 'baha/pre_build'
require 'baha/pre_build/template'

describe Baha::PreBuild::Module::Template do
  let(:dest) { 
    double("dest") 
  }
  let(:config) { 
    double('config') 
  }
  let(:image) { double('image') }
  subject {
    {:config => config, :image => image, 'template' => '/tmp/file', 'dest' => 'dest.txt' }
  }

  describe "#execute" do
    before do
      allow(image).to receive(:workspace).and_return(Pathname.new('/tmp'))
      allow(image).to receive(:env).and_return({:name => 'test'})
      allow(config).to receive(:resolve_file).and_return(nil)
      allow(config).to receive(:resolve_file).with('/tmp/file').and_return('/tmp/file')      
      allow(config).to receive(:resolve_file).with('include.erb').and_return('/tmp/include.erb')
      allow(File).to receive(:read).with('/tmp/file').and_return("<%= name %>")
      allow(File).to receive(:read).with('/tmp/include.erb').and_return("included")
      allow(File).to receive(:open).with(Pathname.new("/tmp/dest.txt"),"w").and_yield(dest)
      allow(dest).to receive(:write)
    end
    it 'writes template content to dest' do
      Baha::PreBuild::Module.execute(subject)
      expect(dest).to have_received(:write).with("test")
    end
    context 'with render function' do
      before do
        allow(File).to receive(:read).with('/tmp/file').and_return("<%= render 'include.erb' %>")
      end
      it 'includes render file' do
        Baha::PreBuild::Module.execute(subject)
        expect(dest).to have_received(:write).with("included")
      end
      it 'raises error when not found' do
        allow(config).to receive(:resolve_file).with('include.erb').and_return(nil)
        expect { Baha::PreBuild::Module.execute(subject) }.to raise_error(ArgumentError)
      end
    end
    context "when template not found" do
      it 'raises ArgumentError' do
        allow(config).to receive(:resolve_file).and_return(nil)
        expect { Baha::PreBuild::Module.execute(subject) }.to raise_error(ArgumentError)
      end
    end
  end
end