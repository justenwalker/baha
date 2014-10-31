require 'spec_helper'

require 'pathname'
require 'baha/pre_build'
require 'baha/pre_build/command'

describe Baha::PreBuild::Module::Command do
  describe "#execute" do
    let(:cmd) { ['echo','Hello'] }
    let(:test) { 'test' }
    let(:stdin) { double('in') }
    let(:output) { double('output') }
    let(:thread) { double('wait') }
    let(:exit_status) { double('exit') }
    let(:config) { double('config') }
    let(:image) { double('image') }
    before do
      allow(image).to receive(:workspace).and_return(Pathname.new('/tmp'))
      allow(output).to receive(:each).and_yield("OUTPUT LINE\n")
      allow(thread).to receive(:value).and_return(exit_status)
      allow(Open3).to receive(:popen2e).with(cmd,:chdir=>'/tmp').and_yield(stdin,output,thread)
    end
    subject {  {'command' => cmd, :image => image, :config => config } }
    it 'runs command' do
      Baha::PreBuild::Module.execute(subject) 
      expect(Open3).to have_received(:popen2e).with(cmd,:chdir=>'/tmp') 
    end
    context "when creates given" do
      subject {  {'command' => cmd,'creates' => 'file', :image => image, :config => config } }
      context "and file exists" do 
        it 'it does not execute' do
          allow_any_instance_of(Pathname).to receive(:exist?).and_return(true)
          Baha::PreBuild::Module.execute(subject)
          expect(Open3).not_to have_received(:popen2e).with(cmd)
        end
      end
      context "and file does not exist" do
        it 'it executes' do
          allow_any_instance_of(Pathname).to receive(:exist?).and_return(false)
          Baha::PreBuild::Module.execute(subject)
          expect(Open3).to have_received(:popen2e).with(cmd,:chdir=>'/tmp')
        end
      end
    end
    context "when onlyif given" do
      subject {  {'command' => cmd,'only_if' => test, :image => image, :config => config } }
      before do
        allow(Open3).to receive(:popen2e).with(test,:chdir=>'/tmp').and_yield(stdin,output,thread)
        allow(Open3).to receive(:popen2e).with(cmd,:chdir=>'/tmp').and_yield(stdin,output,thread)
      end
      context "and returns fail" do 
        it 'it does not execute' do
          allow(exit_status).to receive(:success?).and_return(false)
          Baha::PreBuild::Module.execute(subject)
          expect(Open3).to have_received(:popen2e).with(test,:chdir=>'/tmp')
          expect(Open3).not_to have_received(:popen2e).with(cmd,:chdir=>'/tmp')
        end
      end
      context "and returns success" do
        it 'it executes' do
          allow(exit_status).to receive(:success?).and_return(true)
          Baha::PreBuild::Module.execute(subject)
          expect(Open3).to have_received(:popen2e).with(test,:chdir=>'/tmp')
          expect(Open3).to have_received(:popen2e).with(cmd,:chdir=>'/tmp')
        end
      end
    end
  end
end