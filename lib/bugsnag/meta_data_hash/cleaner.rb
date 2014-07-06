module Bugsnag
  class MetaDataHash
    # The class is responsible for "cleaning" the given object. Cleaning is
    # usually a process of preventing an object from falling into an endless
    # recursion.
    #
    # @example An example of a recursive object
    #   # A recursive array.
    #   array = []
    #   array << 1 << array
    #   puts array #=> [1, [...]]
    #
    # The +array+ object is a dangerous object, and it's not safe to send it.
    # However, A cleaner can deal with it.
    #
    # @example Cleaning the recursive array from the previous example
    #   puts array #=> [1, [...]]
    #   Cleaner.new(array).clean #=> [1, "[RECURSION]"]
    class Cleaner
      attr_reader :obj, :filters, :seen

      # Objects that could possibly lead to recursion and thus to
      # SystemStackError.
      # @return [Array<Class>]
      RECURSIBLE_CLASSES = [Hash, Array, Set]

      # If a cleaner detects recursion it appends a recurion mark in place of
      # a recursible object.
      # @return [String]
      RECURSION_MARK = '[RECURSION]'

      # @param [Object] obj The object to be cleaned
      # @param [Set<String>] filters The set of the fields to be filtered
      # @param [Set<Object>] seen The metacontainer for detecting recursion
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

        yield
      end

      def cleaner
        case obj
        when Hash       then HashCleaner
        when Array, Set then ArrayCleaner
        when Numeric    then NumericCleaner
        when String     then StringCleaner
        else
          DefaultCleaner
        end
      end

      def can_be_recurrent?
        RECURSIBLE_CLASSES.any? { |klass| obj.is_a?(klass) }
      end

      def recursion?(item)
        seen.include?(item)
      end
    end
  end
end
