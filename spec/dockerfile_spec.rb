require 'spec_helper'
require 'baha/config'

describe Baha::Config do
  before do
    ENV['DOCKER_CERT_PATH'] = nil
    ENV['DOCKER_TLS_VERIFY'] = nil
  end
  describe "#parse" do
    context "with valid Dockerfile" do
      subject { Baha::Dockerfile.parse(fixture('Dockerfile.example')) }
      its(['parent']) { should eq('ubuntu:14.04.1')}
      its(['run']) { should eq([
        "echo \"Hello\"", 
        ["/bin/echo", "World"], 
        "echo Hello \nworld \nmultiline"])}
      its(['config']) { should eq({
        "entrypoint"=>["/bin/bash"], 
        "exposedports"=>["8080", "8081", "8009"], 
        "env"=>{
          "HOME"=>"/home/user", 
          "BIN_DIR"=>"bin", 
          "HOME2"=>"/home/user/two", 
          "USER"=>"daemon"}, 
        "workingdir"=>"/home/user/bin/b/c", 
        "cmd"=>"-l", 
        "user"=>"daemon", 
        "volumes"=>[
          "/home/user", 
          "/logs", 
          "/home/user/logs", 
          "/data"]})}
    end
    context "with invalid Dockerfile" do
      it { expect { Baha::Dockerfile.parse(fixture('Dockerfile.invalid')) }.to raise_error(Baha::DockerfileParseError)  }
    end
  end
end
