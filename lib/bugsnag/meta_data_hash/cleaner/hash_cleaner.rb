module Bugsnag
  class MetaDataHash
    class HashCleaner < Cleaner
      FILTER_MARK = '[FILTERED]'

      def initialize(*args)
        super(*args)
        @clean_hash = {}
      end

      def clean
        obj.each do |key, value|
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
