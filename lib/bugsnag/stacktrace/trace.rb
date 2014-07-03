require 'pathname'

module Bugsnag
  class Stacktrace
    class Trace
      # e.g. "org/jruby/RubyKernel.java:1264:in `catch'"
      BACKTRACE_LINE_REGEX = /^((?:[a-zA-Z]:)?[^:]+):(\d+)(?::in `([^']+)')?$/

      # e.g. "org.jruby.Ruby.runScript(Ruby.java:807)"
      JAVA_BACKTRACE_REGEX = /^(.*)\((.*)(?::([0-9]+))?\)$/

      attr_writer :project_root

      def initialize(trace)
        @trace = trace
        @trace_hash = {}

        if trace.match(BACKTRACE_LINE_REGEX)
          @file, @line_str, @method_signature = [$1, $2, $3]
        elsif trace.match(JAVA_BACKTRACE_REGEX)
          @method_signature, @file, @line_str = [$1, $2, $3]
        end
      end

      def skippable?
        @file.nil? || bugsnag_trace? || @file.empty?
      end

      def clean_up
        expand_relative_paths
        clean_up_file_path
        strip_gem_path_prefixes
      end

      # Generate the stacktrace line hash.
      def to_h
        attrs = {
          :inProject => (true if in_project?),
          :method => (@method_signature if includes_method_signature?),
          :lineNumber => @line_str.to_i,
          :file => @file
        }
        @trace_hash.merge!(attrs)
      end

      private

      # Clean up the file path in the stacktrace
      # @return [void]
      def clean_up_file_path
        if (root = Bugsnag.configuration.project_root) && root.to_s != ''
          @file.sub! %r|(#{root})/|, ''
          @project_root = $1
        end
      end

      # Strip common gem path prefixes.
      # @return [void]
      def strip_gem_path_prefixes
        if defined?(Gem)
          Gem.path.inject(@file) { |line, path| line.sub %r|#{path}/|, '' }
        end
      end

      # @return [void]
      def expand_relative_paths
        path = Pathname.new(@file)
        if path.relative?
          @file = path.realpath.to_s rescue @file
        end
      end

      def in_project?
        @project_root && !@project_root.match(%r{vendor/})
      end

      # @return [Boolean]
      def includes_method_signature?
        @method_signature && (@method_signature =~ /^__bind/).nil?
      end

      # Determines if the trace is inside `lib/bugsnag`.
      # @return [Boolean]
      def bugsnag_trace?
        !!(@file =~ %r{lib/bugsnag})
      end
    end
  end
end
