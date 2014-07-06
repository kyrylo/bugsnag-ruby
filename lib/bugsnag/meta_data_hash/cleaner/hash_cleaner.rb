module Bugsnag
  class MetaDataHash
    class HashCleaner < Cleaner
      # If a cleaner was given a set of filters, it will filter the unwanted
      # fields by replacing them with this mark.
      # @return [String]
      FILTER_MARK = '[FILTERED]'

      def initialize(*args)
        super(*args)
        @clean_hash = {}
      end

      def clean
        obj.each do |key, value|
          return RECURSION_MARK if recursion?(value)

          @clean_hash[key] = if any_filters?(key)
                               FILTER_MARK
                             else
                               Cleaner.new(value, filters, seen).clean
                             end
        end

        @clean_hash
      end

      private

      def any_filters?(key)
        filters && filters.any? { |filter| key.to_s.include?(filter.to_s) }
      end
    end
  end
end
