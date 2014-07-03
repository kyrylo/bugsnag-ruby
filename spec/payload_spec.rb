require 'securerandom'

require 'spec_helper'

describe Bugsnag::Payload do
  let(:configuration) { Bugsnag::Configuration.new }
  let(:exception) { RuntimeError.new('It crashed') }
  let(:notification) { Bugsnag::Notification.new(exception, configuration) }
  let(:giant_notification) {
    Bugsnag::Notification.new(exception, configuration, metaData)
  }
  let(:metaData) { { :some_tab => { :giant => SecureRandom.hex(250_000) } } }
  let(:payload) { described_class.new(configuration) }
  let(:payload_with_events) {
    payload.add_event(notification, {}, [exception])
  }
  let(:payload_with_giant_events) {
    3.times { payload.add_event(giant_notification, {}, [exception]) }
    payload
  }

  describe "#new" do
    it "instantiates with no payload events" do
      expect(payload.instance_variable_get(:@data)[:events]).to eq([])
    end
  end

  describe "#add_event" do
    it "adds payload events" do
      expect {
        payload.add_event(notification, {}, [exception])
      }.to change {
        payload.instance_variable_get(:@data)[:events].size
      }.from(0).to(1)
    end

    it "returns self" do
      expect(payload.add_event(notification, {}, [exception]))
        .to eq(payload)
    end
  end

  describe "#api_key=" do
    let(:api_key) { Bugsnag::ApiKey.new('9d84383f9be2ca94902e45c756a9979d') }

    it "sets the api key" do
      expect {
        payload.api_key = api_key
      }.to change {
        payload.instance_variable_get(:@data)[:apiKey]
      }.from(nil).to('9d84383f9be2ca94902e45c756a9979d')
    end
  end

  describe "#events" do
    it "lists payload events" do
      expect {
        3.times { payload.add_event(notification, {}, [exception]) }
      }.to change {
        payload.events.size
      }.from(0).to(3)
    end
  end

  describe "#shrink_metadata!" do
    context "payload without payload events" do
      it "returns an empty array" do
        expect(payload.shrink_metadata!).to eq([])
      end
    end

    context "payload with multiple payload events" do
      subject { payload_with_giant_events }

      it "shrinks each payload event" do
        subject.events.each do |event|
          meta = event.instance_variable_get(:@event)[:metaData]
          expect(meta[:some_tab][:giant]).not_to match(/TRUNCATED/)
        end

        subject.shrink_metadata!

        subject.events.each do |event|
          meta = event.instance_variable_get(:@event)[:metaData]
          expect(meta[:some_tab][:giant]).to match(/TRUNCATED/)
        end
      end
    end
  end

  describe "#to_json" do
    subject { payload.to_json }

    it { expect(subject).to match(/notifier/) }
    it { expect(subject).to match(/name/) }
    it { expect(subject).to match(/version/) }
    it { expect(subject).to match(/url/) }

    context "without payload events" do
      it { expect(subject).not_to match(/events/) }
    end

    context "with payload events" do
      subject { payload_with_events.to_json }

      it { expect(subject).to match(/events/) }
    end
  end

  describe "#length" do
    it "returns the length of the payload in characters" do
      expect(payload.length).to equal(94)
    end
  end
end
