module Bugsnag
  class MetaDataHash
    class DefaultCleaner < Cleaner
      # Avoid leaking potentially sensitive data from objects' #inspect output.
      def clean
        str = obj.to_s
        str =~ /#<.*>/ ?  '[OBJECT]' : str
      end
    end
  end
end
