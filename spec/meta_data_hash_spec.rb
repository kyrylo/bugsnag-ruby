require 'spec_helper'

describe Bugsnag::MetaDataHash do
  class MetaException < Exception
    include Bugsnag::MetaData
  end

  let(:exception) { MetaException.new('It crashed') }
  let(:meta_data) {
    {
      :some_tab => {
        :info => 'here',
        :other_info => 'also here',
      }
    }
  }
  let(:meta_exception) {
    exception.tap { |ex| ex.bugsnag_meta_data = meta_data }
  }
  let(:meta_data_hash) { described_class.new([]) }

  describe "TRUNCATED_MARK" do
    it { expect(described_class::TRUNCATED_MARK).to eq('[TRUNCATED]') }
  end

  describe "CHUNK_MAX_LENGTH" do
    it { expect(described_class::CHUNK_MAX_LENGTH).to equal(4096) }
  end

  describe "DEFAULT_TAB" do
    it { expect(described_class::DEFAULT_TAB).to equal(:custom) }
  end


  describe "#new" do
    context "without meaningful arguments" do
      subject { described_class.new([]).to_h }

      it "sets @meta_data to an empty hash" do
        expect(subject).to eq({})
      end
    end

    context "with exceptions without meta data" do
      subject { described_class.new([Exception.new]).to_h }

      it "doesn't populate @meta_data" do
        expect(subject).to eq({})
      end
    end

    context "with exceptions with meta data" do
      context "overrides present" do
        subject { described_class.new([meta_exception]).to_h }

        it "populates @meta_data with meta data" do
          expect(subject).to eq(meta_data)
        end
      end

      context "overrides absent" do
        let(:overrides) {
          {
            :some_tab => {
              :info => 'overridden',
              :other_info => 'also overridden'
            }
          }
        }

        subject { described_class.new([meta_exception], overrides).to_h }

        it "overrides meta data from exceptions if overrides are present" do
          expect(subject).to eq(overrides)
        end
      end

      context "with filters" do
        let(:filtered_fields) { Set.new(['password'])}
        let(:sensitive_meta_data) {
          { :some_tab => { :info => 'here', :password => 'p4ssw0rd'  } }
        }
        let(:sensitive_exception) {
          exception.tap { |ex| ex.bugsnag_meta_data = sensitive_meta_data }
        }

        subject {
          described_class.new([sensitive_exception], {}, filtered_fields).to_h
        }

        it "filters sensitive meta data" do
          expect(subject)
            .to eq(:some_tab => { :info=>'here', :password=>'[FILTERED]' })
        end
      end
    end
  end

  describe "#add" do
    subject { meta_data_hash.to_h }

    context "value is a hash" do
      context "key exists" do
        before do
          meta_data_hash.add(:some_tab, { :version => 1 })
          meta_data_hash.add(:some_tab, { :subversion => 2 })
        end

        it "merges value with the value behind the key" do
          expect(subject)
            .to eq(:some_tab => { :version => 1, :subversion => 2 })
        end
      end

      context "key is absent" do
        before { expect(subject).to be_empty }

        it "adds a key and a value as meta data" do
          meta_data_hash.add(:some_tab, { :version => 1 })
          expect(subject).to eq(:some_tab => { :version => 1 })
        end
      end
    end

    context "value is not a hash" do
      it "adds a key and a value to the default tab" do
        meta_data_hash.add(:boring, :exception)
        expect(subject).to eq(:custom => { :boring => :exception })
      end
    end
  end

  describe "#truncate" do
    let(:meta_data_hash) { described_class.new([meta_exception]) }

    context "short meta data" do
      subject { meta_data_hash.truncate && meta_data_hash.to_h }

      it "is not getting truncated" do
        expect(subject).to eq(meta_data)
      end
    end

    context "long meta data" do
      let(:meta_data) {
        {
          :some_tab => {
            :giant => SecureRandom.hex(10_000 / 2),
            :mega => SecureRandom.hex(5_000 / 2),
          }
        }
      }

      it "truncates it" do
        expect {
          meta_data_hash.truncate
        }.to change {
          tab = meta_data_hash.to_h[:some_tab]
          [tab[:giant].size, tab[:mega].size]
        }.from([10_000, 5_000]).to([4107, 4107])
      end

      it "appends the truncated mark to the end" do
        expect(meta_data_hash.to_h[:some_tab][:giant])
          .not_to match(/\[TRUNCATED\]/)
        expect(meta_data_hash.to_h[:some_tab][:mega])
          .not_to match(/\[TRUNCATED\]/)

        meta_data_hash.truncate

        expect(meta_data_hash.to_h[:some_tab][:giant])
          .to match(/\[TRUNCATED\]/)
        expect(meta_data_hash.to_h[:some_tab][:mega])
          .to match(/\[TRUNCATED\]/)
      end
    end
  end
end
