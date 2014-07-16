module Bugsnag
  class Payload
    # Responsible for delivering payload as JSON to an endpoint. Requires an API
    # key. The method for delivering payload is POST. For POSTing the class
    # uses HTTParty. The class forbids very long payload and truncates it if
    # it's too long. The result of
    # @see Bugsnag::Payload
    class TransferAgent
      include HTTParty

      # HTTParty settings.
      headers  'Content-Type' => 'application/json'
      default_timeout 5

      # @return [Integer] the maximum number of characters in a JSON version of
      #   payload
      MAX_PAYLOAD_LENGTH = 128000

      attr_reader :response

      # @param [String] api_key The key to the Bugsnag endpoint
      # @param [Bugsnag::Payload] payload The information to be delivered
      def initialize(api_key, payload)
        @api_key = api_key
        @payload = payload
        @response = nil
      end

      # Performs a POST request to the +endpoint+ with +@payload+. Truncates
      # long payloads. Writes the results of a request to the +response+ slot.
      # @param [String] endpoint
      # @return [void]
      def deliver_to(endpoint)
        # If the payload is going to be too long, we trim the hashes to send a
        # minimal payload instead.
        @payload.shrink_metadata! if @payload.length > MAX_PAYLOAD_LENGTH

        @payload.api_key = @api_key

        begin
          @response = self.class.post(endpoint, :body => @payload.to_json)
          Bugsnag.debug(
            "Notification to #{endpoint} finished, response was " +
            "#{@response.code} payload was #{@payload.to_json}"
          )
        rescue StandardError => e
          # KLUDGE: Since we don't re-raise http exceptions, this breaks rspec
          raise if e.class.to_s == 'RSpec::Expectations::ExpectationNotMetError'

          Bugsnag.warn("Notification to #{endpoint} failed, #{e.inspect}")
          Bugsnag.warn(e.backtrace)
        end
      end
    end
  end
end
