module Bugsnag
  # This class acts as a hash with Bugsnag's meta data about exceptions. It's
  # endowed with ability to generate data from given exceptions (in
  # understandable for Bugsnag format) and truncate it, if it's too long.
  #
  # @example Storing information from custom exceptions
  #   # Create a custom exception with ability to attach meta data.
  #   class MyCustomException < Exception
  #     include Bugsnag::MetaData
  #   end
  #
  #   exception = MyCustomException.new("It broke!")
  #
  #   # Attach some infomration to the exception.
  #   exception.bugsnag_meta_data = {
  #     :user_info => { name: 'Ezequiel' }
  #   }
  #
  #   # Store exception in a meta data hash.
  #   meta = MetaDataHash.new([exception])
  #   #=> #<... @meta_data={:user_info=>{:name=>"Ezequiel"}}>
  #
  # Each node (+:user_info+ from the example above) represents a tab on the
  # Bugsnag's website. MetaDataHash is capable of storing and managing tabs and
  # information contained within them. By default data goes to the Custom tab.
  #
  # @example Adding data to the Custom tab.
  #   meta #=> <... @meta_data={}>
  #   meta.add(:foo, 'bar') <... @meta_data={:custom=>{:foo=>"bar"}}>
  class MetaDataHash
    extend Forwardable

    def_delegators :@meta_data, :[], :[]=, :delete

    # The mark appended to the end of data on successful truncation.
    TRUNCATED_MARK = '[TRUNCATED]'

    # The maximum number of characters in a chunk of data.
    CHUNK_MAX_LENGTH = 4096

    # The tab on bugsnag.com, which receives meta data by default.
    DEFAULT_TAB = :custom

    # @return [Hash]
    attr_reader :meta_data

    def initialize(exceptions, overrides = {}, filters = Set.new)
      @meta_data = Cleaner.new(generate(exceptions, overrides), filters).clean
    end

    def add(key, value)
      insert(@meta_data, key, value)
    end

    def truncate
      @meta_data = reduce_hash_size(@meta_data)
    end

    private

    # Generate the meta data from both the request configuration, the
    # overrides and the exceptions for this notification.
    def generate(exceptions, overrides)
      tempdata = {}

      exceptions.each do |exception|
        if has_attached_meta_data?(exception)
          exception.bugsnag_meta_data.each do |key, value|
            insert(tempdata, key, value)
          end
        end
      end

      overrides.each { |key, value| insert(tempdata, key, value) }

      tempdata
    end

    def has_attached_meta_data?(exception)
      exception.class.include?(Bugsnag::MetaData) &&
        exception.bugsnag_meta_data && !exception.bugsnag_meta_data.empty?
    end

    def insert(data, key, value)
      if value.is_a?(Hash)
        if data[key]
          data[key].merge!(value)
        else
          data[key] = value
        end
      else
        data[DEFAULT_TAB] ||= {}
        data[DEFAULT_TAB][key] = value
      end
    end

    def reduce_hash_size(hash)
      hash.inject({}) do |h, (k, v)|
        if v.is_a?(Hash)
          h[k] = reduce_hash_size(v)
        elsif v.is_a?(Array) || v.is_a?(Set)
          h[k] = v.map { |el| reduce_hash_size(el) }
        else
          val = v.to_s
          if val.length > CHUNK_MAX_LENGTH
            val = val.slice(0, CHUNK_MAX_LENGTH) + TRUNCATED_MARK
          end
          h[k] = val
        end

        h
      end
    end
  end
end
