module Bugsnag
  class MetaDataHash
    class Cleaner
      attr_reader :obj, :filters, :seen

      RECURSIBLE_CLASSES = [Hash, Array, Set]

      RECURSION_MARK = '[RECURSION]'

      def initialize(obj, filters = Set.new, seen = Set.new)
        @obj = obj
        @filters = filters
        @seen = seen
      end

      def clean
        return unless obj

        protect_from_recursion do
          cleaner.new(obj, filters, seen).clean
        end
      end

      private

      # Protect against recursion of recursable items.
      def protect_from_recursion
        if can_be_recurrent?
          # Make sure that no updates by further clean calls are persisted
          # beyond that call.
          @seen = seen.dup
          @seen << obj
        end

        return RECURSION_MARK if recursion?

        yield
      end

      def cleaner
        Kernel.const_get("::Bugsnag::MetaDataHash::#{obj.class}Cleaner")
      end

      def can_be_recurrent?
        RECURSIBLE_CLASSES.any? { |klass| obj.is_a?(klass) }
      end

      def recursion?
        seen.include?(obj)
      end
    end
  end
end
