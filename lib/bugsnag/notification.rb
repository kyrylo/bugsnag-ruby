require "httparty"
require "multi_json"
require "pathname"

module Bugsnag
  class Notification
    NOTIFIER_NAME = "Ruby Bugsnag Notifier"
    NOTIFIER_VERSION = Bugsnag::VERSION
    NOTIFIER_URL = "http://www.bugsnag.com"

    API_KEY_REGEX = /[0-9a-f]{32}/i

    SUPPORTED_SEVERITIES = ["error", "warning", "info"]

    CURRENT_PAYLOAD_VERSION = "2"

    attr_accessor :context
    attr_accessor :user
    attr_accessor :configuration
    attr_reader :exceptions

    class << self
      def deliver_exception_payload(endpoint, payload)
        begin
          payload_string = Bugsnag::Helpers.dump_json(payload)

          # If the payload is going to be too long, we trim the hashes to send
          # a minimal payload instead
          if payload_string.length > 128000
            payload[:events].each {|e| e[:metaData] = Bugsnag::Helpers.reduce_hash_size(e[:metaData])}
            payload_string = Bugsnag::Helpers.dump_json(payload)
          end

          deliveryman = Notification::Deliveryman.new
          deliveryman.deliver(:to => endpoint, :payload => payload_string)
          Bugsnag.debug("Notification to #{endpoint} finished, response was #{deliveryman.response.code}, payload was #{payload_string}")
        rescue StandardError => e
          # KLUDGE: Since we don't re-raise http exceptions, this breaks rspec
          raise if e.class.to_s == "RSpec::Expectations::ExpectationNotMetError"

          Bugsnag.warn("Notification to #{endpoint} failed, #{e.inspect}")
          Bugsnag.warn(e.backtrace)
        end
      end
    end

    def initialize(exception, configuration, overrides = nil, request_data = nil)
      @exceptions = ExceptionUnwrapper.unwrap(exception)
      @configuration = configuration
      @overrides = Bugsnag::Helpers.flatten_meta_data(overrides) || {}
      @request_data = request_data

      @meta_data = {}
      @user = {}

      self.severity = @overrides[:severity]
      @overrides.delete :severity

      if @overrides.key? :grouping_hash
        self.grouping_hash = @overrides[:grouping_hash]
        @overrides.delete :grouping_hash
      end

      if @overrides.key? :api_key
        self.api_key = @overrides[:api_key]
        @overrides.delete :api_key
      end

      self.class.http_proxy(configuration.proxy_host, configuration.proxy_port, configuration.proxy_user, configuration.proxy_password) if configuration.proxy_host
      self.class.default_timeout(configuration.timeout) if configuration.timeout
    end

    # Add a single value as custom data, to this notification
    def add_custom_data(name, value)
      @meta_data[:custom] ||= {}
      @meta_data[:custom][name.to_sym] = value
    end

    # Add a new tab to this notification
    def add_tab(name, value)
      return if name.nil?

      if value.is_a? Hash
        @meta_data[name.to_sym] ||= {}
        @meta_data[name.to_sym].merge! value
      else
        self.add_custom_data(name, value)
        Bugsnag.warn "Adding a tab requires a hash, adding to custom tab instead (name=#{name})"
      end
    end

    # Remove a tab from this notification
    def remove_tab(name)
      return if name.nil?

      @meta_data.delete(name.to_sym)
    end

    def user_id=(user_id)
      @user[:id] = user_id
    end

    def user_id
      @user[:id]
    end

    def user=(user = {})
      return unless user.is_a? Hash
      @user.merge!(user).delete_if{|k,v| v == nil}
    end

    def severity=(severity)
      @severity = severity if SUPPORTED_SEVERITIES.include?(severity)
    end

    def severity
      @severity || "warning"
    end

    def payload_version
      CURRENT_PAYLOAD_VERSION
    end

    def grouping_hash=(grouping_hash)
      @grouping_hash = grouping_hash
    end

    def grouping_hash
      @grouping_hash || nil
    end

    def api_key=(api_key)
      @api_key = api_key
    end

    def api_key
      @api_key ||= @configuration.api_key
    end

    # Deliver this notification to bugsnag.com Also runs through the middleware as required.
    def deliver
      return unless @configuration.should_notify?

      # Check we have at least an api_key
      if api_key.nil?
        Bugsnag.warn "No API key configured, couldn't notify"
        return
      elsif api_key !~ API_KEY_REGEX
        Bugsnag.warn "Your API key (#{api_key}) is not valid, couldn't notify"
        return
      end

      # Warn if no release_stage is set
      Bugsnag.warn "You should set your app's release_stage (see https://bugsnag.com/docs/notifiers/ruby#release_stage)." unless @configuration.release_stage

      @meta_data = {}

      # Run the middleware here, at the end of the middleware stack, execute the actual delivery
      @configuration.middleware.run(self) do
        # Now override the required fields
        exceptions.each do |exception|
          if exception.class.include?(Bugsnag::MetaData)
            if exception.bugsnag_user_id.is_a?(String)
              self.user_id = exception.bugsnag_user_id
            end
            if exception.bugsnag_context.is_a?(String)
              self.context = exception.bugsnag_context
            end
          end
        end

        [:user_id, :context, :user, :grouping_hash].each do |symbol|
          if @overrides[symbol]
            self.send("#{symbol}=", @overrides[symbol])
            @overrides.delete symbol
          end
        end

        # Build the endpoint url
        endpoint = (@configuration.use_ssl ? "https://" : "http://") + @configuration.endpoint
        Bugsnag.log("Notifying #{endpoint} of #{@exceptions.last.class} from api_key #{api_key}")

        # Build the payload's exception event
        payload_event = {
          :app => {
            :version => @configuration.app_version,
            :releaseStage => @configuration.release_stage,
            :type => @configuration.app_type
          },
          :context => self.context,
          :user => @user,
          :payloadVersion => payload_version,
          :exceptions => exception_list,
          :severity => self.severity,
          :groupingHash => self.grouping_hash,
          :metaData => Bugsnag::Helpers.cleanup_obj(generate_meta_data(@exceptions, @overrides), @configuration.params_filters)
        }.reject {|k,v| v.nil? }

        payload_event[:device] = {:hostname => @configuration.hostname} if @configuration.hostname

        # Build the payload hash
        payload = {
          :apiKey => api_key,
          :notifier => {
            :name => NOTIFIER_NAME,
            :version => NOTIFIER_VERSION,
            :url => NOTIFIER_URL
          },
          :events => [payload_event]
        }

        self.class.deliver_exception_payload(endpoint, payload)
      end
    end

    def ignore?
      ignore_exception_class? || ignore_user_agent?
    end

    def request_data
      @request_data || Bugsnag.configuration.request_data
    end

    private

    def ignore_exception_class?
      ex = @exceptions.last
      @configuration.ignore_classes.any? do |to_ignore|
        to_ignore.is_a?(Proc) ? to_ignore.call(ex) : to_ignore == error_class(ex)
      end
    end

    def ignore_user_agent?
      if @configuration.request_data && @configuration.request_data[:rack_env] && (agent = @configuration.request_data[:rack_env]["HTTP_USER_AGENT"])
        @configuration.ignore_user_agents.any? do |to_ignore|
          agent =~ to_ignore
        end
      end
    end

    # Generate the meta data from both the request configuration, the overrides and the exceptions for this notification
    def generate_meta_data(exceptions, overrides)
      # Copy the request meta data so we dont edit it by mistake
      meta_data = @meta_data.dup

      exceptions.each do |exception|
        if exception.class.include?(Bugsnag::MetaData) && exception.bugsnag_meta_data
          exception.bugsnag_meta_data.each do |key, value|
            add_to_meta_data key, value, meta_data
          end
        end
      end

      overrides.each do |key, value|
        add_to_meta_data key, value, meta_data
      end

      meta_data
    end

    def add_to_meta_data(key, value, meta_data)
      # If its a hash, its a tab so we can just add it providing its not reserved
      if value.is_a? Hash
        key = key.to_sym

        if meta_data[key]
          # If its a clash, merge with the existing data
          meta_data[key].merge! value
        else
          # Add it as is if its not special
          meta_data[key] = value
        end
      else
        meta_data[:custom] ||= {}
        meta_data[:custom][key] = value
      end
    end

    def exception_list
      @exceptions.map do |exception|
        {
          :errorClass => error_class(exception),
          :message => exception.message,
          :stacktrace => stacktrace(exception)
        }
      end
    end

    def error_class(exception)
      # The "Class" check is for some strange exceptions like Timeout::Error
      # which throw the error class instead of an instance
      (exception.is_a? Class) ? exception.name : exception.class.name
    end

    def stacktrace(exception)
      stacktrace = Stacktrace.new(exception, @configuration.project_root)
      stacktrace.filter_map { |trace| trace.clean_up && trace.to_h }
    end
  end
end
