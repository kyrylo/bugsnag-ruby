module Bugsnag
  class MetaDataHash
    class ArrayCleaner < Cleaner
      def clean
        clean_obj = obj.map do |el|
          break RECURSION_MARK if recursion?(el)
          Cleaner.new(el, filters, seen).clean
        end

        clean_obj.compact! if clean_obj.instance_of?(Array)
        clean_obj
      end
    end
  end
end
