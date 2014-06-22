# -*- coding: utf-8 -*-
require 'spec_helper'
require 'securerandom'

describe Bugsnag::Notification::Deliveryman do
  def notify_test_exception(*args)
    Bugsnag.notify(RuntimeError.new("test message"), *args)
  end

  describe "#deliver" do
    it "truncates large meta_data before sending" do
      truncated_hash = 4096
      rest_of_payload = 5000

      expect_any_instance_of(described_class).to receive(:deliver) do |_, opts|
        expect(opts[:payload].length).to be < 2*truncated_hash + rest_of_payload
      end

      Bugsnag.notify(BugsnagTestException.new("It crashed"), {
          :meta_data => {
            :some_tab => {
              :giant => SecureRandom.hex(500_000/2),
              :mega => SecureRandom.hex(500_000/2)
            }
          }
        }
      )
    end

    it "fixes invalid utf8" do
      invalid_data = "fl\xc3ff"
      if invalid_data.respond_to?(:force_encoding)
        invalid_data.force_encoding('BINARY')
      end

      expect_any_instance_of(described_class).to receive(:deliver) do |_, opts|
        expect(opts[:payload]).to match(/fl�ff/) if defined?(Encoding::UTF_8)
      end

      notify_test_exception(:fluff => {:fluff => invalid_data})
    end
  end
end
