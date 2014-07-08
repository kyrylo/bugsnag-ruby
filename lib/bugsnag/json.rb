module Bugsnag
  # A namespace for JSON functions. It also works around MultiJson changes in
  # 1.3+.
  module JSON
    def self.dump(object, options = {})
      if modern_multi_json?
        MultiJson.dump(object, options)
      else
        MultiJson.encode(object, options)
      end
    end

    def self.load_json(json, options = {})
      if modern_multi_json?
        MultiJson.load(json, options)
      else
        MultiJson.decode(json, options)
      end
    end

    private

    def self.modern_multi_json?
      MultiJson.respond_to?(:adapter)
    end
  end
end
