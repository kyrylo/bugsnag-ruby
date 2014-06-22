module Bugsnag
  class Stacktrace
    def initialize(exception, project_root)
      @exception_traces = tracify(exception.backtrace || caller, project_root)
    end

    def filter_map
      traces = @exception_traces.map do |trace|
        next if trace.skippable?
        yield trace
      end

      traces.compact
    end

    private

    def tracify(backtrace, project_root)
      backtrace.map { |bt| Trace.new(bt, project_root) }
    end
  end
end
