require 'spec_helper'

describe Bugsnag::MetaDataHash::Cleaner do

  describe "RECURSIBLE_CLASSES" do
    it { expect(described_class::RECURSIBLE_CLASSES).to eq([Hash, Array, Set]) }
  end

  describe "RECURSION_MARK" do
    it { expect(described_class::RECURSION_MARK).to eq('[RECURSION]') }
  end

  describe "#clean" do
    it "returns nil if object is nil" do
      expect(described_class.new(nil).clean).to be_nil
    end

    it "protects from recursion" do

    end

    it "cleans obj from crap"

     it "cleans up recursive hashes" do
    a = {:a => {}}
    a[:a][:b] = a
    expect(Bugsnag::Helpers.cleanup_obj(a)).to eq({:a => {:b => "[RECURSION]"}})
  end

  it "cleans up recursive arrays" do
    a = []
    a << a
    a << "hello"
    expect(Bugsnag::Helpers.cleanup_obj(a)).to eq(["[RECURSION]", "hello"])
  end

  it "allows multiple copies of the same string" do
    a = {:name => "bugsnag"}
    a[:second] = a[:name]
    expect(Bugsnag::Helpers.cleanup_obj(a)).to eq({:name => "bugsnag", :second => "bugsnag"})
  end

  it "allows multiple copies of the same object" do
    a = []
    b = ["hello"]
    a << b; a << b
    expect(Bugsnag::Helpers.cleanup_obj(a)).to eq([["hello"], ["hello"]])
  end


  end

end
