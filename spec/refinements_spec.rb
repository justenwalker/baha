require 'spec_helper'
require 'baha/refinements'

describe "Baha::Refinements" do
  using Baha::Refinements
  describe "Hash#[]" do
    let(:h) {
      {
        :symkey   => 100,
        "strkey"  => 200
      }
    }
    it { expect(h[:symkey]).to  eq(100) }
    it { expect(h['symkey']).to eq(100) }
    it { expect(h[:strkey]).to  eq(200) }
    it { expect(h['strkey']).to eq(200) }
  end
  describe "Hash#pick" do
    let(:h) {
      {
        :a => 'a',
        :z => 'z'
      }
    }
    it { expect(h.pick([:a,:b,:c])).to  eq('a') }
    it { expect(h.pick([:x,:y,:z])).to  eq('z') }
    it { expect(h.pick([:x,:y])).to  be_nil }
    it { expect(h.pick([:x,:y],'z')).to eq('z') }
  end
end
