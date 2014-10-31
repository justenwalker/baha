require 'spec_helper'
require 'baha/image'

describe Baha::Image do
  let(:config) do
    Baha::Config.new({
      'defaults' => {
        'parent' => 'ubuntu:14.04.1',
        'repository' => 'docker.example.com/baha',
        'maintainer' => 'Ishmael <ishmael@example.com>',
        'bind' => '/.baha',
        'command' => ['/bin/bash','/.baha/init.sh']
      }
    })
  end
  let(:image) do 
    {
      'parent'     => 'ubuntu:14.04.1',
      'name'       => 'base',
      'tag'        => '1.0.0',
      'maintainer' => '"Captain Ahab" <ahab@example.com>',
      'bind'       => '/.data',
      'command'    => ['/bin/bash','/.data/setup.sh']
    }
  end
  subject { described_class.new(config,image) }

  describe "#inspect" do
    its(:inspect) { should match(/^Baha::Image<(@[a-z0-9_]+=.*)+>$/) }
  end

  describe "#parent_id" do
    let(:parent) { double('parent') }
    it 'returns parent full id if available' do
      allow(Baha::Image).to receive(:get_image!).and_return(parent)
      allow(parent).to receive(:id).and_return('AAAA')
      expect(subject.parent_id).to eq('AAAA')
    end
  end

  describe "#parse_name" do
    subject { Baha::Image.parse_name(@name)}
    it 'parses full name' do
      @name = "docker.example.com/repo/name:tag"
      is_expected.to eq({:ns=>"docker.example.com/repo", :name=>"name", :tag=>"tag"})
    end
    it 'parses local name' do
      @name = "name:tag"
      is_expected.to eq({:ns=>nil, :name=>"name", :tag=>"tag"})
    end
    it 'sets default tag to latest' do
      @name = "name"
      is_expected.to eq({:ns=>nil, :name=>"name", :tag=>"latest"})
    end
    it 'raises error on invalid name' do
      expect { Baha::Image.parse_name("@@@@@@") }.to raise_error(ArgumentError)
    end
  end

  describe "#parse_with_default" do
    subject { Baha::Image.parse_with_default(@name,'default.example.com/baha')}
    it 'does not override repos' do
      @name = "docker.example.com/repo/name:tag"
      is_expected.to eq({:ns=>"docker.example.com/repo", :name=>"name", :tag=>"tag"})
    end
    it 'sets default namespace' do
      @name = "name:tag"
      is_expected.to eq({:ns=>"default.example.com/baha", :name=>"name", :tag=>"tag"})
    end
  end

  context "when constructed" do
    its(:parent) { is_expected.to eq({:ns=>"docker.example.com/baha", :name=>"ubuntu", :tag=>"14.04.1"}) }
    its(:image) { is_expected.to eq({:ns=>"docker.example.com/baha", :name=>"base", :tag=>"1.0.0"}) }
    its(:maintainer) { is_expected.to eq('"Captain Ahab" <ahab@example.com>') }
    its(:options) { is_expected.to be_a(Hash) }
    its(:bind) { is_expected.to eq('/.data')}
    its(:command) { is_expected.to eq(['/bin/bash','/.data/setup.sh']) }
    its(:env) { is_expected.to include(
      {:parent => {:ns=>"docker.example.com/baha", :name=>"ubuntu", :tag=>"14.04.1"}},
      {:maintainer => "\"Captain Ahab\" <ahab@example.com>"},
      {:bind => '/.data'},
      {:name => 'base'},
      {:tag => '1.0.0'},
      :workspace) }
  end

  describe "#get_image!" do
    let(:image) do
      {
        :ns    => 'docker.example.com/baha',
        :name  => 'base',
        :tag   => '1.0.0'
      }
    end
    subject { Baha::Image.get_image!(image) }
    context 'when image exists locally' do
      before :example do
        mock_registry([
          {:id => 'BBBB', :name => 'base',   :tag => '1.0.0', :pulled => true, :parent => 'AAAA', :tags => ['base:1.0.0']}
        ])
      end
      it { should_not be_nil }
    end
    context 'when base image exists' do
      before :example do
        mock_registry([
          {:id => 'BBBB', :name => 'base',   :tag => '1.0.0', :parent => 'AAAA', :tags => ['base:1.0.0']}
        ])
      end
      it { should_not be_nil }
    end
    context 'when base image exists remotely' do
      before :example do
        mock_registry([
          {:id => 'BBBB', :name => 'base',   :tag => '1.0.0', :parent => 'AAAA', :tags => ['docker.example.com/baha/base:1.0.0']}
        ])
      end
      it { should_not be_nil }
    end
  end

  describe "#needs_update?" do
    context 'when parent does not exist' do
      before :example do
        mock_registry([])
      end
      it { expect{ subject.needs_update? }.to raise_error(Baha::ImageNotFoundError) }
    end
    context 'when base does not exist' do
      before :example do
        mock_registry([
          {:id => 'AAAA', :name => 'ubuntu', :tag => '14.04.1', :tags => ['ubuntu:14.04.1']},
          {:id => 'BBBB', :name => 'base', :tag => '1.0.0', :tags => ['base:1.0.0'], :not_found => true}
        ])
      end
      it { expect(subject.needs_update?).to be(true) }
    end
    context 'when parent has changed' do
      before :example do
        mock_registry([
          {:id => 'AAAA', :name => 'ubuntu', :tag => '14.04.1', :tags => ['ubuntu:14.04.1']},
          {:id => 'CCCC', :name => 'base',   :tag => '1.0.0', :parent => 'BBBB', :tags => ['docker.example.com/baha/base:1.0.0']}
        ])
      end
      it { expect(subject.needs_update?).to be(true) }
    end
    context 'when tags have changed' do
      before :example do
        mock_registry([
          {:id => 'AAAA', :name => 'ubuntu', :tag => '14.04.1', :tags => ['ubuntu:14.04.1']},
          {:id => 'CCCC', :name => 'base',   :tag => '1.0.0', :parent => 'BBBB', :tags => ['docker.example.com/baha/base:0.9.0']}
        ])
      end
      it { expect(subject.needs_update?).to be(true) }
    end
    context 'when up to date' do
      before :example do
        mock_registry([
          {:id => 'AAAA', :name => 'ubuntu', :tag => '14.04.1', :tags => ['ubuntu:14.04.1']},
          {:id => 'BBBB', :name => 'base',   :tag => '1.0.0', :parent => 'AAAA', :tags => ['docker.example.com/baha/base:1.0.0']}
        ])
      end
      it { expect(subject.needs_update?).to be(false) }
    end
  end
end