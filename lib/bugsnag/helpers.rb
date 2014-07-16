module Bugsnag
  module Helpers
    def self.cleanup_url(url, filters = nil)
      return url unless filters

      filter_regex = Regexp.new("([?&](?:[^&=]*#{filters.to_a.join('|[^&=]*')}[^&=]*)=)[^&]*")

      url.gsub(filter_regex, '\1[FILTERED]')
    end
  end
end
