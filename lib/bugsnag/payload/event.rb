module Bugsnag
  class Payload
    class Event
      CURRENT_PAYLOAD_VERSION = '2'

      def initialize(configuration, notification, user, exceptions)
        @meta_data = notification.meta_data
        @event = {
          :app => {
            :version => configuration.app_version,
            :releaseStage => configuration.release_stage,
            :type => configuration.app_type
          },
          :context => notification.context,
          :user => user,
          :payloadVersion => CURRENT_PAYLOAD_VERSION,
          :exceptions => ExceptionList.new(exceptions).to_h,
          :severity => notification.severity,
          :groupingHash => notification.grouping_hash,
          :metaData => @meta_data,
          :device => ({:hostname => configuration.hostname} if configuration.hostname)
        }.reject { |key, value| value.nil? }
      end

      def shrink_metadata!
        @event[:metaData] = @event[:metaData].truncate
      end
    end
  end
end
