# -*- coding: utf-8 -*-
require 'spec_helper'

describe Bugsnag::Payload::TransferAgent do

  describe "MAX_PAYLOAD_LENGTH" do
    it { expect(described_class::MAX_PAYLOAD_LENGTH).to equal(128000) }
  end

  describe "#deliver_to" do
    let(:truncated_hash_size) { 4096 }
    let(:rest_of_payload_size) { 5000 }
    let(:api_key) { '9d84383f9be2ca94902e45c756a9979d' }
    let(:endpoint) { 'http://example.com' }
    let(:limit) { 2*truncated_hash_size + rest_of_payload_size }
    let(:payload) {
      exception = RuntimeError.new('It crashed')
      config = Bugsnag::Configuration.new
      meta_data = {
        :some_tab => {
          :giant => SecureRandom.hex(500_000/2),
          :mega => SecureRandom.hex(500_000/2)
        }
      }
      notification = Bugsnag::Notification.new(exception, config, meta_data)
      p = Bugsnag::Payload.new(config)
      p.add_event(notification, {}, [exception])
    }

    context "giant payload" do
      subject { described_class.new(api_key, payload) }

      before do
        payload_length = subject.instance_variable_get(:@payload).length
        expect(payload_length).to be > limit
      end

      it "shrinks the payload's metadata before delivering it" do
        subject.deliver_to(endpoint)
        payload_length = subject.instance_variable_get(:@payload).length
        expect(payload_length).to be < limit
      end
    end

    context "API key" do
      let(:agent) { described_class.new(api_key, payload) }
      subject {
        agent
          .instance_variable_get(:@payload)
          .instance_variable_get(:@data)[:apiKey]
      }

      it "sets an API key to the payload" do
        agent.deliver_to(endpoint)
        expect(subject).to eq(api_key)
      end
    end
  end

end
