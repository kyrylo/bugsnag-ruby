require 'spec_helper'

describe Bugsnag::MetaDataHash::ArrayCleaner do

  describe "#clean" do
    context "basic recursion" do
      let(:recursive_array) {
        a = []; a << a << 'hello' << a
      }
      subject { described_class.new(recursive_array).clean }

      it "cleans up recursive array" do
        expect(subject).to eq(['[RECURSION]', 'hello', '[RECURSION]'])
      end
    end

    context "deep recursion" do
      let(:super_recursive_array) {
        a = []; a << [[a], 'a', a] << 'b' << [a, 'c']
      }
      subject { described_class.new(super_recursive_array).clean }

      it "cleans up deeply recursed array" do
        expect(subject).to eq(
          [
            [['[RECURSION]'], 'a', '[RECURSION]'],
            'b',
            ['[RECURSION]', 'c']
          ]
        )
      end
    end

    context "array with multiple copies of the same object" do
      let(:array_with_the_same_object) {
        a = []
        b = ["hello"]
        a << b; a << b
      }
      subject { described_class.new(array_with_the_same_object).clean }

      it "does not modify the array" do
        expect(subject).to eq([['hello'], ['hello']])
      end
    end
  end

end
