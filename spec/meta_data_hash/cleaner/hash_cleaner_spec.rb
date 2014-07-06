require 'spec_helper'

describe Bugsnag::MetaDataHash::HashCleaner do

  describe "FILTER_MARK" do
    it { expect(described_class::FILTER_MARK).to eq('[FILTERED]') }
  end

  describe "#clean" do
    context "recursion" do
      let(:recursive_hash) {
        h = { :a => {} }
        h[:a][:b] = h
        h
      }
      subject { described_class.new(recursive_hash).clean }

      it "cleans up recursive hash" do
        expect(subject).to eq(
          :a => {
            :b => '[RECURSION]'
          }
        )
      end
    end

    context "hash with multiple copies of the same the same string" do
      let(:hash_with_the_same_string) {
        a = { :name => 'bugsnag' }
        a[:name_copy] = a[:name]
        a
      }
      subject { described_class.new(hash_with_the_same_string).clean }

      it "does not modify the hash" do
        expect(subject).to eq(:name => 'bugsnag', :name_copy => 'bugsnag')
      end
    end

    context "filtration" do
      let(:hash) {
        {
          :name => 'Sadie',
          :password => 'p4ssw0rd'
        }
      }

      context "without filters" do
        subject { described_class.new(hash).clean }

        it "doesn't filter fields without filters" do
          expect(subject).to eq(:name => 'Sadie', :password => 'p4ssw0rd')
        end
      end

      context "with filters" do
        let(:filters) { Set.new(['password']) }
        subject { described_class.new(hash, filters).clean }

        it "filters given fields with filters" do
          expect(subject).to eq(:name => 'Sadie', :password => '[FILTERED]')
        end
      end
    end
  end

end
