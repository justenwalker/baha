require 'spec_helper'
require 'baha/config'
require 'baha/pre_build'

describe Baha::Builder do
  let(:task) do
    { 'download' => '', 'url' => 'http://www.google.com', 'file' => 'out.txt' }
  end
  let(:badtask) do
    { 'no_such_module' => 'throws error' }
  end

  describe "#execute" do
    context 'with valid task' do
      before do
        allow(Baha::PreBuild::Module).to receive(:module_download)
        Baha::PreBuild::Module.execute(task)
      end
      it 'exeecutes module' do
        expect(Baha::PreBuild::Module).to have_received(:module_download).with(instance_of(Baha::PreBuild::Module))
      end
    end
    context 'with invalid task' do
      it do
        expect { Baha::PreBuild::Module.execute(badtask) }.to raise_error(Baha::PreBuild::ModuleNotFoundError)
      end
    end
  end
end