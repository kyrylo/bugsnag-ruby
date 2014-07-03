module HTTParty
  class Parser
    def json
      Bugsnag::Helpers.load_json(body)
    end
  end
end

module Bugsnag
  module Helpers
    def self.cleanup_url(url, filters = nil)
      return url unless filters

      filter_regex = Regexp.new("([?&](?:[^&=]*#{filters.to_a.join('|[^&=]*')}[^&=]*)=)[^&]*")

      url.gsub(filter_regex, '\1[FILTERED]')
    end

    def self.load_json(json, options={})
      if MultiJson.respond_to?(:adapter)
        MultiJson.load(json, options)
      else
        MultiJson.decode(json, options)
      end
    end
  end
end
