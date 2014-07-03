module Bugsnag
  class MetaDataHash
    class StringCleaner < Cleaner
      def clean
        if utf8_support?
          if obj.encoding == Encoding::UTF_8
            if obj.valid_encoding?
              obj
            else
              obj.encode('utf-16', {:invalid => :replace, :undef => :replace})
                .encode('utf-8')
            end
          else
            obj.encode('utf-8', {:invalid => :replace, :undef => :replace})
          end
        elsif defined?(Iconv)
          Iconv.conv('UTF-8//IGNORE', 'UTF-8', obj) || obj
        else
          obj
        end
      end

      private

      def utf8_support?
        !!(defined?(obj.encoding) && defined?(Encoding::UTF_8))
      end
    end
  end
end
