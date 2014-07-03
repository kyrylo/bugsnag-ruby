module Bugsnag
  class MetaDataHash
    class ArrayCleaner < Cleaner
      def clean
        obj.map { |el| Cleaner.new(el, filters, seen).clean }.compact
      end
    end
  end
end
