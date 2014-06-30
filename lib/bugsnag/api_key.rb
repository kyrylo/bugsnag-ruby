module Bugsnag
  class ApiKey
    VALID_API_KEY_REGEX = /\A[0-9a-f]{32}\z/i

    def initialize(key)
      @key = key.to_s
    end

    def to_s
      @key
    end

    def valid?
      if @key.empty?
        Bugsnag.warn "No API key configured, couldn't notify"
      elsif @key !~ VALID_API_KEY_REGEX
        Bugsnag.warn "Your API key (#{@key}) is not valid, couldn't notify"
      else
        return true
      end

      false
    end
  end
end
