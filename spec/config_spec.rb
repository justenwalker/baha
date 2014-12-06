require 'spec_helper'
require 'baha/config'

describe Baha::Config do
  before do
    ENV['DOCKER_CERT_PATH'] = nil
    ENV['DOCKER_TLS_VERIFY'] = nil
  end
  describe "#load" do
    context "with embedded images" do
      subject { Baha::Config.load(fixture('config_embedded.yml')) }
      its(:defaults) { should eq(
        {
          :parent=>"ubuntu:14.04.1", 
          :bind=>"/.baha", 
          :repository=>'docker.example.com/baha', 
          :maintainer => "Ishmael <ishmael@example.com>",
          :command => ['/bin/bash','./init.sh'],
          :timeout => 1200
        }) 
      }
      its(:options) { should eq({}) }
      its(:configdir) { should eq(fixture_path) }
      its(:workspace) { should eq(fixture_path + 'workspace') }
    end
    context "with included image files" do
      subject { Baha::Config.load(fixture('config_include.yml')) }
      its(:defaults) { should eq(
        {
          :parent=>"ubuntu:14.04.1", 
          :bind=>"/.baha", 
          :repository=>'docker.example.com/baha', 
          :maintainer => "Ishmael <ishmael@example.com>",
          :command => ['/bin/bash','./init.sh'],
          :timeout => 1200
        }) 
      }
      its(:options) { should eq({}) }
      its(:configdir) { should eq(fixture_path) }
      its(:workspace) { should eq(fixture_path + 'workspace') }
    end
    context "with dockerfile" do
      subject { Baha::Config.load(fixture('config_dockerfile.yml')) }
      its(:defaults) { should eq(
        {
          :parent=>"ubuntu:14.04.1", 
          :bind=>"/.baha", 
          :repository=>'docker.example.com/baha', 
          :maintainer => "Ishmael <ishmael@example.com>",
          :command => ['/bin/bash','./init.sh'],
          :timeout => 1200
        }) 
      }
      its(:options) { should eq({}) }
      its(:configdir) { should eq(fixture_path) }
      its(:workspace) { should eq(fixture_path + 'workspace') }
    end
    context "with DOCKER_CERT_PATH set" do
      subject { Baha::Config.load(fixture('config_embedded.yml')) } 
      before do
        ENV['DOCKER_CERT_PATH'] = '/tmp'
        ENV['DOCKER_TLS_VERIFY'] = nil
      end
      its(:options) { should eq({:client_cert=>"/tmp/cert.pem", :client_key=>"/tmp/key.pem", :ssl_ca_file=>"/tmp/ca.pem", :ssl_verify_peer=>false}) }
      its(:secure) { should eq(true) }
      context "with DOCKER_TLS_VERIFY=1" do
        before do
          ENV['DOCKER_CERT_PATH'] = '/tmp'
          ENV['DOCKER_TLS_VERIFY'] = '1'
        end
        its(:options) { should eq({:client_cert=>"/tmp/cert.pem", :client_key=>"/tmp/key.pem", :ssl_ca_file=>"/tmp/ca.pem", :ssl_verify_peer=>true}) }
      end
    end
    context "with ssl in config" do
      subject { Baha::Config.load(fixture('config_ssl.yml')) }
      its(:options) { should eq({:client_cert=>"cert.pem", :client_key=>"key.pem", :ssl_ca_file=>"ca.pem", :ssl_verify_peer=>true}) }
      its(:secure) { should eq(true) }
    end
    context "with ssl cert_path" do
      subject { Baha::Config.load(fixture('config_sslpath.yml')) }
      its(:options) { should eq({:client_cert=>"/ssl/cert.pem", :client_key=>"/ssl/key.pem", :ssl_ca_file=>"/ssl/ca.pem", :ssl_verify_peer=>true}) }
      its(:secure) { should eq(true) }
    end
  end
  describe "#init_docker!" do
    subject { Baha::Config.load(fixture('config_ssl.yml')) }
    before do
      allow(Docker).to receive(:validate_version!)
      subject.init_docker!
    end
    it { expect(Docker).to have_received(:validate_version!) }
    it { expect(Docker.url).to eq('https://127.0.1.1:2375') }
    it { expect(Docker.options).to eq({:client_cert=>"cert.pem", :client_key=>"key.pem", :ssl_ca_file=>"ca.pem", :ssl_verify_peer=>true}) }
  end
  describe "#inspect" do
    subject { Baha::Config.load(fixture('config_embedded.yml')) }
    its(:inspect) { should match(/^Baha::Config<(@[a-z0-9_]+=.*)+>$/) }
  end
  describe "#each_image" do
    subject { Baha::Config.load(fixture('config_eachimage.yml')) }
    it 'loads images it can find' do
      images = []
      subject.each_image do |image|
        images << image
      end
      expect(images.size).to eq(3)
    end
  end
end