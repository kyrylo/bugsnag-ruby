module Bugsnag
  class Stacktrace

    attr_reader :project_root

    def initialize(exception)
      @exception_traces = tracify(exception)
    end

    def project_root=(project_root)
      @exception_traces.each do |et|
        et.project_root = project_root
      end
      @project_root = project_root
    end

    def filter_map
      @exception_traces.map { |trace|
        next if trace.skippable?
        yield trace
      }.compact
    end

    private

    def tracify(exception)
      (exception.backtrace || caller).map { |bt| Trace.new(bt) }
    end
  end
end
