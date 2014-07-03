require 'httparty'
require 'multi_json'

module Bugsnag
  class Notification
    class Deliveryman
      include HTTParty

      # HTTParty settings
      headers  'Content-Type' => 'application/json'
      default_timeout 5

      MAX_PAYLOAD_LENGTH = 128000

      attr_reader :response

      def initialize(api_key, payload)
        @api_key = api_key
        @payload = payload
        @response = nil
      end

      def deliver_to(endpoint)
        # If the payload is going to be too long, we trim the hashes to send a
        # minimal payload instead.
        @payload.shrink_metadata! if @payload.length > MAX_PAYLOAD_LENGTH

        @payload.api_key = @api_key

        begin
          @response = self.class.post(endpoint, {:body => @payload.to_json})
          Bugsnag.debug("Notification to #{endpoint} finished, response was #{@response.code}, payload was #{@payload.to_json}")
        rescue StandardError => e
          # KLUDGE: Since we don't re-raise http exceptions, this breaks rspec
          raise if e.class.to_s == "RSpec::Expectations::ExpectationNotMetError"

          Bugsnag.warn("Notification to #{endpoint} failed, #{e.inspect}")
          Bugsnag.warn(e.backtrace)
        end
      end
    end
  end
end
