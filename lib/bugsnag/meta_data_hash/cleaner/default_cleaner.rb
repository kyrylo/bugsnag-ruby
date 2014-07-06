module Bugsnag
  class MetaDataHash
    class DefaultCleaner < Cleaner
      SECURITY_MARK = '[OBJECT]'

      # Avoid leaking potentially sensitive data from objects' #inspect output.
      def clean
        str = obj.to_s
        str =~ /#<.*>/ ? SECURITY_MARK : str
      end
    end
  end
end
