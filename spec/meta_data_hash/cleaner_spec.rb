require 'spec_helper'

describe Bugsnag::MetaDataHash::Cleaner do

  describe "RECURSIBLE_CLASSES" do
    it { expect(described_class::RECURSIBLE_CLASSES).to eq([Hash, Array, Set]) }
  end

  describe "RECURSION_MARK" do
    it { expect(described_class::RECURSION_MARK).to eq('[RECURSION]') }
  end

  describe "#clean" do
    context "@obj is nil" do
      it "returns nil" do
        expect(described_class.new(nil).clean).to be_nil
      end
    end

    context "recursion" do
      context "for recursible objects" do
        let(:recursible_objects) {
          {
            :array => [1, 2, 3],
            :set => Set.new([1, 2, 3]),
            :hash => { :a => 1, :b => 2, :c => 3 }
          }
        }

        shared_examples "recursible objects" do |obj_name|
          context "#{obj_name}" do
            subject { described_class.new(recursible_objects[obj_name]) }

            it "stores the object in @seen" do
              expect {
                subject.clean
              }.to change {
                subject.seen
              }.from(Set.new).to(Set.new([recursible_objects[obj_name]]))
            end
          end
        end

        [:array, :set, :hash].each do |obj_key|
          include_examples "recursible objects", obj_key
        end
      end
    end

    context "for non-recursible objects" do
      let(:nonrecursible_objects) {
        {
          :numeric => Numeric.new,
          :fixnum => 1,
          :string => 'string',
          :float => 1.01
        }
      }

      shared_examples "non-recursible objects" do |obj_name|
        context "#{obj_name}" do
          subject { described_class.new(nonrecursible_objects[obj_name]) }

          it "ignores objects and doesn't store them in @seen" do
            expect { subject.clean }.not_to change { subject.seen }
          end
        end
      end

      [:numeric, :fixnum, :string, :float].each do |obj_key|
        include_examples 'non-recursible objects', obj_key
      end
    end
  end

end
