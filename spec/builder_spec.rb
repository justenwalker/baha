require 'spec_helper'
require 'baha/config'
require 'baha/builder'
require 'fileutils'

describe Baha::Builder do
  let(:config) do
    Baha::Config.load(fixture('config_build.yml'))
  end
  subject { described_class.new(config) }

  describe "#new" do
    it 'loads config file from filename' do
      expect { described_class.new(fixture('config_build.yml')) }.not_to raise_error
    end
  end

  describe "#inspect" do
    its(:inspect) { should match(/^Baha::Builder<(@[a-z0-9_]+=.*)+>$/) }
  end

  describe "#build!" do
    before do
      allow_any_instance_of(Baha::Config).to receive(:init_docker!)
      allow(Baha::PreBuild::Module).to receive(:execute)
      allow(FileUtils).to receive(:mkdir_p)
    end
    context "when no update needed" do
      before do
        allow_any_instance_of(Baha::Image).to receive(:needs_update?).and_return(false)
        subject.build!
      end
      it 'does not execute pre_build' do
        expect(Baha::PreBuild::Module).not_to have_received(:execute)
      end
    end
    context "when update needed" do
      let(:container) {
        double('container')
      }
      let(:image) {
        double('image')
      }
      let(:image2) {
        double('image2')
      }
      let (:init) {
        double('init.sh')
      }
      before do
        allow_any_instance_of(Baha::Image).to receive(:needs_update?).and_return(true)
        allow_any_instance_of(Baha::Image).to receive(:parent_id).and_return('AAAA')
        allow(Docker::Container).to receive(:create).and_return(container)
        allow(File).to receive(:open).with(pathname_matching(/init.sh$/),'w').and_yield(init)
        allow(File).to receive(:open).with(pathname_matching(/.yml$/),/r/).and_call_original
        allow(File).to receive(:open).with(pathname_matching(/Dockerfile/),/r/).and_call_original
        allow(container).to receive(:start)
        allow(container).to receive(:stop)
        allow(container).to receive(:streaming_logs).with({"stdout"=>true, "stderr"=>true, "follow"=>true, "timestamps"=>false}).and_yield(:stdout,"console message").and_yield(:stderr,"error line")
        allow(container).to receive(:wait).with(1200).and_return({'StatusCode' => 0})
        allow(container).to receive(:commit).and_return(image)
        allow(image).to receive(:id).and_return('BBBB')
        allow(Docker::Image).to receive(:get).with('BBBB').and_return(image)
        allow(image).to receive(:tag)
        allow(container).to receive(:remove)
        allow(init).to receive(:write)
      end
      it 'executes pre_build step' do
        subject.build!
        expect(Baha::PreBuild::Module).to have_received(:execute).twice.with(hash_including('download' => "http://www.google.com"))
      end
      it 'write run script' do
        subject.build!
        expect(init).to have_received(:write).with("#!/bin/sh\n").ordered
        expect(init).to have_received(:write).with("set -xe\n").ordered
        expect(init).to have_received(:write).with("echo \"Hello\"\n").ordered
        expect(init).to have_received(:write).with("/bin/echo World\n").ordered
      end
      it 'creates containers' do
        subject.build!
        expect(Docker::Container).to have_received(:create).twice.with({"Image"=>"AAAA", "Cmd"=>["/bin/bash", "./init.sh"], "Workingdir"=>"/.baha"})
      end
      it 'starts containers' do
        subject.build!
        expect(container).to have_received(:start).exactly(3).times
      end
      it 'commits containers' do
        subject.build!
        expect(container).to have_received(:commit).with({"run"=>{"ExposedPorts"=>{"8080/tcp"=>{}, "8081/tcp"=>{}, "8009/tcp"=>{}}}}).ordered
        expect(container).to have_received(:commit).with({'run' => {}}).ordered
      end
      it 'tags image' do
        subject.build!
        expect(image).to have_received(:tag).with({:repo=>"docker.example.com/baha/base", :tag=>"1.0.0"})
        expect(image).to have_received(:tag).with({:repo=>"docker.example.com/baha/base", :tag=>"latest"})
        expect(image).to have_received(:tag).with({:repo=>"base", :tag=>"1.0.0"})
        expect(image).to have_received(:tag).with({:repo=>"base", :tag=>"latest"})
        expect(image).to have_received(:tag).with({:repo=>"docker.example.com/baha/derived", :tag=>"1.0.0"})
        expect(image).to have_received(:tag).with({:repo=>"docker.example.com/baha/derived", :tag=>"latest"})
        expect(image).to have_received(:tag).with({:repo=>"derived", :tag=>"1.0.0"})
        expect(image).to have_received(:tag).with({:repo=>"derived", :tag=>"latest"})
      end
      context "when error building image" do
        before do
          allow(container).to receive(:wait).with(1200).and_return({'StatusCode' => 1})
        end
        it { expect {  subject.build! }.to raise_error(Baha::Builder::BuildError) }
      end
      context "when exception building image" do
        before do
          allow(container).to receive(:wait).with(1200).and_raise(Exception)
        end
        it { expect {  subject.build! }.to raise_error(Baha::Builder::BuildError) }
      end
    end
  end
end