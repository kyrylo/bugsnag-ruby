# -*- coding: utf-8 -*-
require 'spec_helper'

describe Bugsnag::MetaDataHash::StringCleaner do

  describe "#clean" do
    context "UTF-8 strings" do
      subject { described_class.new('André').clean }
      it { expect(subject).to eq('André') }
    end

    context "binary strings" do
      let(:string) {
        "Andr\xc7\xff".tap do |str|
          if str.respond_to?(:force_encoding)
            str.replace(str.force_encoding('BINARY'))
          end
        end
      }

      subject { described_class.new(string).clean }

      it "cleans up it", :exclude_ancient_ruby => true do
        expect(subject).to eq("Andr��")
      end
    end
  end

end
