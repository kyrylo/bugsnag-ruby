module Bugsnag
  class Payload
    class Event
      CURRENT_PAYLOAD_VERSION = '2'

      attr_reader :event

      def initialize(configuration, notification, user, exceptions)
        @configuration = configuration
        @event = {
          :app => app,
          :context => notification.context,
          :user => user,
          :payloadVersion => CURRENT_PAYLOAD_VERSION,
          :exceptions => ExceptionList.new(exceptions).to_h,
          :severity => notification.severity,
          :groupingHash => notification.grouping_hash,
          :metaData => notification.meta_data,
          :device => device
        }
      end

      def shrink_metadata!
        @event[:metaData] = @event[:metaData].truncate
      end

      def to_h
        h = @event.reject do |k, v|
          v.nil? || (v.respond_to?(:empty?) && v.empty?)
        end
        h[:metaData] = @event[:metaData].to_h
        @event.merge(h)
      end

      private

      def app
        {
          :version => @configuration.app_version,
          :releaseStage => @configuration.release_stage,
          :type => @configuration.app_type
        }.reject { |k, v| v.nil? }
      end

      def device
        if @configuration.hostname
          { :hostname => @configuration.hostname }
        end
      end
    end
  end
end
