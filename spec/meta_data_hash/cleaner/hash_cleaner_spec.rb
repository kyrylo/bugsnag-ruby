require 'spec_helper'

describe Bugsnag::MetaDataHash::HashCleaner do

  describe "#clean" do
    let(:recursive_hash) {
      h = { :a => {} }
      h[:a][:b] = h
      h
    }

    subject { described_class.new(recursive_hash).clean }

    it "cleans up recursive hash" do
      expect(subject).to eq(:a => { :b => '[RECURSION]'})
    end
  end

end
