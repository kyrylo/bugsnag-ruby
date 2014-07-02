module Bugsnag
  # Represents a list of exceptions that can be converted to a hash with
  # predefined structure, suitable for the Bugsnag API. The hash contains a name
  # of the exceptions' class (+:errorClass+), a descriptive reason of failure
  # (+:message+) and a stacktrace (+:stacktrace+).
  #
  # @example
  #   list = ExceptionList.new([RuntimeError.new, StandardError.new])
  #   list.to_h
  #   #=> []
  class ExceptionList
    # @param [Array<Exception>] exceptions The list of exceptions to be
    #   inspected
    def initialize(exceptions = [])
      @exceptions = exceptions
    end

    # @return [Array<Hash>]
    def to_h
      @exceptions.map do |exception|
        { :errorClass => error_class(exception),
          :message => exception.message,
          :stacktrace => stacktrace(exception) }
      end
    end

    private

    # The "Class" check is for some strange exceptions like Timeout::Error
    # which throw the error class instead of an instance.
    def error_class(exception)
      exception.is_a?(Class) ? exception.name : exception.class.name
    end

    def stacktrace(exception)
      Stacktrace.new(exception).filter_map do |trace|
        trace.clean_up && trace.to_h
      end
    end
  end
end
