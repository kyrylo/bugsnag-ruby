require 'spec_helper'

describe Bugsnag::ExceptionList do
  let(:runtime_error) { RuntimeError.new('It failed') }
  let(:standard_error) { StandardError.new }

  describe "#to_h" do
    describe "return values" do
      subject { described_class.new([runtime_error, standard_error]).to_h }

      it { expect(subject).to be_a(Array) }
      it { expect(subject.size).to equal(2) }
      it { expect(subject.first).to be_a(Hash) }
      it { expect(subject.last).to be_a(Hash) }
    end

    describe "hash contents" do
      subject { described_class.new([runtime_error]).to_h.first }

      it "sets errorClass" do
        expect(subject[:errorClass]).to eq('RuntimeError')
      end

      it "sets message" do
        expect(subject[:message]).to eq('It failed')
      end

      it "sets stacktrace" do
        expect(subject[:stacktrace]).not_to be_empty
      end
    end

    context "empty list" do
      it "returns an empty array" do
        expect(described_class.new.to_h).to eq([])
      end
    end
  end

end
