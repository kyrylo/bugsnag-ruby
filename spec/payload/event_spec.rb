require 'spec_helper'

describe Bugsnag::Payload::Event do
  describe "CURRENT_PAYLOAD_VERSION" do
    it { expect(described_class::CURRENT_PAYLOAD_VERSION).to eq('2') }
  end

  describe "#new" do
  end

  describe "#shrink_metadata!" do
  end
end
