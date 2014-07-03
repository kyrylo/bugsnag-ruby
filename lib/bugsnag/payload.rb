require 'multi_json'

module Bugsnag
  # Represents data that is meant to be sent to the Bugsnag servers.
  class Payload
    DEFAULT_NOTIFIER = {
      :name => 'Ruby Bugsnag Notifier',
      :version => Bugsnag::VERSION,
      :url => 'http://www.bugsnag.com'
    }

    def initialize(configuration)
      @configuration = configuration
      @data = {
        :notifier => DEFAULT_NOTIFIER,
        :events => []
      }
    end

    def add_event(notification, user, exceptions)
      event = Event.new(@configuration, notification, user, exceptions)
      @data[:events] << event
      self
    end

    def api_key=(api_key)
      @data[:apiKey] = api_key.to_s
    end

    def events
      @data[:events]
    end

    def shrink_metadata!
      events.each(&:shrink_metadata!)
    end

    # Works around MultiJson changes in 1.3+.
    def to_json
      if MultiJson.respond_to?(:adapter)
        MultiJson.dump(filtered_data, {})
      else
        MultiJson.encode(filtered_data, {})
      end
    end

    def length
      to_json.length
    end

    private

    def filtered_data
      @data.reject { |k, v| v.empty? }
    end
  end
end
