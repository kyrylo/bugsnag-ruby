require 'spec_helper'

describe Bugsnag::JSON do

  describe ".dump" do
    let(:ruby_object) { { :foo => :bar } }
    subject { described_class.dump(ruby_object) }

    it "encodes a Ruby object as JSON" do
      expect(subject).to eq('{"foo":"bar"}')
    end
  end

  describe ".load_json" do
    let(:json_string) { '{"foo":"bar"}' }
    subject { described_class.load(json_string) }

    it "decodes a JSON string into Ruby" do
      expect(subject).to eq('foo' => 'bar')
    end
  end

end
