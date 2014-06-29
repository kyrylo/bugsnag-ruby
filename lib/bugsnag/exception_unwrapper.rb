module Bugsnag
  # Creates a helper object which is capable of unwrapping exceptions. An
  # exception to unwrap must be set explicitly. The class supports multiple
  # Rubies.
  # @example An example of a wrapped exception
  #   begin
  #     begin
  #       raise "Error A"
  #     rescue => error
  #       raise MyError, "Error B"
  #     end
  #   rescue => error
  #     puts "Current failure: #{error.inspect}"
  #     puts "Original failure:  #{error.original_exception.inspect}"
  #   end
  #
  # In the example above the original `error` must implement the
  # `#original_exception` method. Rubies lower than 2.1 do not support debugging
  # of wrapped exceptions, but we can fake them with help of this method.
  # @example The API
  #   ExceptionUnwrapper.unwrap(StandardError.new)
  #   #=> [#<StandardError: StandardError>]
  #
  #   ExceptionUnwrapper.unwrap(nested_exception)
  #   #=> [#<StandardError: StandardError>, #<RuntimeError: RuntimeError>]
  # @see http://devblog.avdi.org/2013/12/25/exception-causes-in-ruby-2-1/
  class ExceptionUnwrapper
    # The nesting level.
    UNWRAP_MAX = 5

    # Unwraps up to +UNWRAP_MAX+ exceptions.
    # @return [Array<Exception>] the array of exceptions where the first element
    #   is always the original exception itself and the next elements are the
    #   nested exceptions.
    def self.unwrap(ex)
      unwrapper = self.new
      exceptions = []

      UNWRAP_MAX.times do
        break if ex.nil? || exceptions.include?(ex)
        exceptions << unwrapper.set_exception(ex).convert
        ex = unwrapper.unwrap_exception
      end

      exceptions
    end

    def initialize
      @ex = Exception.new
    end

    # @return [ExceptionUnwrapper] self
    def set_exception(ex)
      @ex = ex
      self
    end

    def convert
      @ex = get_exception || @ex
      @ex = convert_to_runtime_error || @ex
      @ex
    end

    def unwrap_exception
      if ruby21_exception?
        @ex.cause
      elsif continued_exception?
        @ex.continued_exception
      elsif nested_exception?
        @ex.original_exception
      end
    end

    private

    def get_exception
      unless exception?
        if @ex.respond_to?(:to_exception)
          @ex.to_exception
        elsif ex.respond_to?(:exception)
          @ex.exception
        end
      end
    end

    def convert_to_runtime_error
      return unless jruby_exception?
      Bugsnag.warn("Converting non-Exception to RuntimeError: #{@ex.inspect}")
      RuntimeError.new(@ex.to_s)
    end

    def exception?
      @ex.is_a?(Exception)
    end

    def throwable?
      !!defined?(::Java::JavaLang::Throwable) &&
        @ex.is_a?(::Java::JavaLang::Throwable)
    end

    def jruby_exception?
      exception? && throwable?
    end

    # @see http://devblog.avdi.org/2013/12/25/exception-causes-in-ruby-2-1/
    def ruby21_exception?
      @ex.respond_to?(:cause) && @ex.cause
    end

    # Support for +ActionView::Template::Error+.
    # @see https://bugsnag.com/blog/ruby-2-1-exception-causes
    def nested_exception?
      @ex.respond_to?(:original_exception) && @ex.original_exception
    end

    # TODO: find out what it is.
    def continued_exception?
      @ex.respond_to?(:continued_exception) && @ex.continued_exception
    end
  end
end
