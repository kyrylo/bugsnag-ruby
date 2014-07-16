module Bugsnag
  # Payload is a top-level collection of data that consists of events. It is
  # meant to be sent to the Bugsnag endpoint. A new payload object does not have
  # any events. It is your responsibility to add them. A payload can be
  # converted to JSON with help of the +#to_json+ method. The API of the class
  # also allows shrinking of metadata (reducing the event information). This
  # operation is dangerous as it modifies the object and truncates long
  # metadata. You can always check how big your payload is with help of the
  # +#length+ method.
  #
  # @see Payload::Event
  # @see #to_json
  class Payload
    DEFAULT_NOTIFIER = {
      :name => 'Ruby Bugsnag Notifier',
      :version => Bugsnag::VERSION,
      :url => 'http://www.bugsnag.com'
    }

    # @param [Bugsnag::Configuration] configuration The various configuration
    #   options
    def initialize(configuration)
      @configuration = configuration
      @data = {
        :notifier => DEFAULT_NOTIFIER,
        :events => []
      }
    end

    # Creates and stores a payload event based on the given arguments, such as
    # the array of exceptions.
    # @param [Bugsnag::Notification] notification
    # @param [Hash] user
    # @param [Array<Exception>] exceptions
    # @return [Bugsnag::Payload] self
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

    # Shrinks meta data of each event of the payload.
    # @note This is a destructive method
    # @return [void]
    def shrink_metadata!
      events.each(&:shrink_metadata!)
    end

    def to_json
      Bugsnag::JSON.dump(filtered_data)
    end

    # @return [Integer] how many characters a JSON representation of the object
    #   has
    def length
      to_json.length
    end

    private

    def filtered_data
      tempdata = @data.reject { |k, v| v.empty? }
      tempdata[:events] = events.map(&:to_h)
      tempdata.reject { |k, v| v.empty? }
    end
  end
end
