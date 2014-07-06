require 'spec_helper'

describe Bugsnag::MetaDataHash::DefaultCleaner do
  describe "RECURSION_MARK" do
    it { expect(described_class::SECURITY_MARK).to eq('[OBJECT]') }
  end

  context "object with default #to_s" do
    subject { Object.new }
    before { expect(subject.to_s).to match(/#<Object:.+>/) }

    it "wipes out objects' metainformation for the sake of safety" do
      expect(described_class.new(subject).clean).to eq('[OBJECT]')
    end
  end

  context "object with non-standard #inspect" do
    class NonStandardInspect
      def to_s; 'OBJECT: @password=p4ssw0rd'; end
    end

    subject { NonStandardInspect.new }

    it "doesn't do anything to the inspect" do
      expect(described_class.new(subject).clean)
        .to eq('OBJECT: @password=p4ssw0rd')
    end
  end
end
