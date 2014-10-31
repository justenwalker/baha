require 'spec_helper'
require 'baha/log'
require 'stringio'

shared_examples "a logger" do |level|
  subject { Baha::Log.for_name("specs") }
  before do
    Baha::Log.level = :debug
  end
  let(:loglevel) { level.to_s.upcase }
  let(:regex) {
    Regexp.new("^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}.[0-9]{3} \\[\\s*#{loglevel}\\] specs -- Hello$")
  }
  context "when given a block" do
    it 'prints a valid message' do
      subject.send(level) { "Hello" }
      expect(io.string).to match(regex)
    end
  end
  context "when given a string" do
    it 'prints a valid message' do
      subject.send(level,"Hello")
      expect(io.string).to match(regex)
    end
  end
  context "when given an object" do
    it 'prints object.inspect' do
      subject.send(level,{ :hello => 'world' })
      expect(io.string).to match("specs -- {:hello=>\"world\"}")
    end
  end
  context "when given an exception" do
    it 'prints a exception backtrace' do
      begin
        raise ArgumentError.new("Hello")
      rescue Exception => e
        subject.send(level,e)
      end
      expect(io.string).to match(/specs -- Hello \(ArgumentError\)\n((.+?):(\d+)(|:in `(.+)')\n)+/)
    end
  end
end

describe Baha::Log do
  subject { Baha::Log }
  
  before do
    Baha::Log.level = :error
  end

  it { expect(Baha::Log.level).to eq(:error) }

  describe "#level=" do
    it 'sets level' do
      Baha::Log.level = "WARN"
      expect(Baha::Log.level).to eq(:warn)   
    end
    it 'raises error on invalid input type' do
      expect { Baha::Log.level = 123 }.to raise_error(ArgumentError)   
    end
    it 'raises error on invalid level' do
      expect { Baha::Log.level = 'NOTALEVEL' }.to raise_error(ArgumentError)   
    end
  end
  
  describe "#for_name" do
    subject { Baha::Log.for_name("specs") }
    it { expect(subject).not_to be_nil }
    its(:progname) { should eq("specs") }
  end

  context 'with log instance' do
    let(:io) { StringIO.new }
    before do
      Baha::Log.logfile = io
    end
    it_behaves_like "a logger", :debug
    it_behaves_like "a logger", :info
    it_behaves_like "a logger", :warn
    it_behaves_like "a logger", :error
    it_behaves_like "a logger", :fatal
    describe "#close!" do
      before do
        subject.close!
      end
      it { expect(io.closed?).to eq(true) }      
    end
  end
end