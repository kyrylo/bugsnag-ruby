require 'httparty'
require 'multi_json'

module Bugsnag
  class Notification
    class Deliveryman
      include HTTParty

      # HTTParty settings
      headers  'Content-Type' => 'application/json'
      default_timeout 5

      attr_reader :response

      def initialize
        @response = nil
      end

      def deliver(opts)
        @response = self.class.post(opts[:to], {:body => opts[:payload]})
      end
    end
  end
end
