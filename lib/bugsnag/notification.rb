require "httparty"

module Bugsnag
  class Notification
    SEVERITIES = ['error', 'warning', 'info']

    attr_accessor :context
    attr_accessor :user
    attr_accessor :configuration

    attr_reader :exceptions
    attr_reader :meta_data

    def initialize(exception, configuration, overrides = nil, request_data = nil)
      @exceptions = ExceptionUnwrapper.unwrap(exception)
      @configuration = configuration
      @overrides = flatten_meta_data(overrides)
      @request_data = request_data

      @user = {}
      @payload = Payload.new(configuration)

      self.severity = @overrides[:severity]
      @overrides.delete(:severity)

      if @overrides.key?(:grouping_hash)
        self.grouping_hash = @overrides[:grouping_hash]
        @overrides.delete(:grouping_hash)
      end

      if @overrides.key?(:api_key)
        self.api_key = ApiKey.new(@overrides[:api_key])
        @overrides.delete(:api_key)
      end

      @meta_data = MetaDataHash.new(@exceptions, @overrides,
        configuration.params_filters)

      if configuration.proxy_host
        self.class.http_proxy(
          configuration.proxy_host,
          configuration.proxy_port,
          configuration.proxy_user,
          configuration.proxy_password
        )
      end

      if configuration.timeout
        self.class.default_timeout(configuration.timeout)
      end
    end

    def add_tab(name, value)
      return unless name

      if value.is_a?(Hash)
        @meta_data[name.to_sym] ||= {}
        @meta_data[name.to_sym].merge! value
      else
        @meta_data.add(name, value)
        Bugsnag.warn "Adding a tab requires a hash, adding to custom tab instead (name=#{name})"
      end
    end

    def remove_tab(name)
      return unless name

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
      @severity = severity if SEVERITIES.include?(severity)
    end

    def severity
      @severity || "warning"
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

    # Deliver this notification to bugsnag.com Also runs through the middleware
    # as required.
    def deliver
      return false if !@configuration.should_notify? || !api_key.valid?

      # Warn if no release_stage is set
      if @configuration.release_stage.nil?
        Bugsnag.warn "You should set your app's release_stage (see https://bugsnag.com/docs/notifiers/ruby#release_stage)."
      end

      # Run the middleware here, at the end of the middleware stack, execute the
      # actual delivery.
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

        Bugsnag.log("Notifying #{endpoint} of #{@exceptions.last.class} from api_key #{api_key}")

        @payload.add_event(self, @user, @exceptions)
        Payload::TransferAgent.new(api_key, @payload).deliver_to(endpoint)
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

    def flatten_meta_data(overrides)
      return {} unless overrides

      meta_data = overrides.delete(:meta_data)
      if meta_data.is_a?(Hash)
        overrides.merge!(meta_data)
      else
        overrides
      end
    end

    def endpoint
      protocol = (@configuration.use_ssl ? 'https://' : 'http://')
      protocol + @configuration.endpoint
    end
  end
end
