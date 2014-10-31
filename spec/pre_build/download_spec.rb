require 'spec_helper'

require 'pathname'
require 'baha/pre_build'
require 'baha/pre_build/download'

describe Baha::PreBuild::Module::Download do
  let(:file) { 
    double("file") 
  } 
  let(:url) { 
    double("url") 
  }
  let(:config) { 
    double('config') 
  }
  let(:image) { double('image') }
  subject {
    {:config => config, :image => image, 'download' => 'http://www.google.com/', 'file' => 'url' }
  }

  describe "#execute" do
    before do
      allow(file).to receive(:write)
      allow(url).to receive(:read).and_return('content')
      allow(Baha::PreBuild::Module::Download).to receive(:open).with('http://www.google.com/','rb').and_yield(url)
      allow(File).to receive(:open)
      allow(File).to receive(:open).with(Pathname.new('/tmp/url'),'w').and_yield(file)
      allow(image).to receive(:workspace).and_return(Pathname.new('/tmp'))
    end
    it 'downloads url to file' do
      Baha::PreBuild::Module.execute(subject)
      expect(file).to have_received(:write).with("content")
    end
    context "when file exists" do
      it 'does not download file' do
        allow_any_instance_of(Pathname).to receive(:exist?).and_return(true)
        Baha::PreBuild::Module.execute(subject)
        expect(file).not_to have_received(:write)
      end
    end
  end
end