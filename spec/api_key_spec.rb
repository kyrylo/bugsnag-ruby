require 'spec_helper'

describe Bugsnag::ApiKey do

  describe "#to_s" do
    it "returns an empty string if the constructor received an empty string" do
      expect(described_class.new('').to_s).to eq('')
    end

    it "returns an empty string if the constructor received a nil" do
      expect(described_class.new(nil).to_s).to eq('')
    end

    it "returns an invalid key if the constructor received an invalid key" do
      invalid_key = ';d8438)f9be2ca94902e45c7,6a9979.'
      expect(described_class.new(invalid_key).to_s).to eq(invalid_key)
    end

    it "returns a valid key if the constructor received a valid key" do
      valid_key = '9d84383f9be2ca94902e45c756a9979d'
      expect(described_class.new(valid_key).to_s).to eq(valid_key)
    end
  end

  describe "#valid?" do
    it "returns false if the key is empty" do
      expect(described_class.new('').valid?).to be_falsey
    end

    it "returns false if the key is nil" do
      expect(described_class.new(nil).valid?).to be_falsey
    end

    it "returns false if the key has unwanted symbols" do
      expect(described_class.new(';d8438)f9be2ca94902e45c7,6a9979.').valid?)
        .to be_falsey
    end

    it "returns false if the key is shorter than 32 symbols" do
      expect(described_class.new('d84383f9be2ca94902e45c756a9979').valid?)
        .to be_falsey
    end

    it "returns false if the key is longer than 32 symbols" do
      expect(described_class.new('9d84383f9be2ca94902e45c756a9979d123d').valid?)
        .to be_falsey
    end

    it "returns false if the key has wrong characters (such as g-z)" do
      expect(described_class.new('zd8438uf9be2ca94902e45c7i6a9979k').valid?)
        .to be_falsey
    end

    it "does not care about the key case if the key is invalid" do
      invalid = described_class.new('zd8438uf9be2ca94902e45c7i6a9979k').valid?
      other_invalid =
        described_class.new('ZD8438UF9BE2CA94902E45C7I6A9979K').valid?

      expect(invalid).to equal(other_invalid)
    end

    it "does not care about the key case if the key is valid" do
      valid = described_class.new('9d84383f9be2ca94902e45c756a9979d').valid?
      other_valid =
        described_class.new('9D84383F9BE2CA94902E45C756A9979D').valid?

      expect(valid).to equal(other_valid)
    end

    it "returns true if the key is good" do
      expect(described_class.new('9d84383f9be2ca94902e45c756a9979d').valid?)
        .to be_truthy
    end
  end

end
