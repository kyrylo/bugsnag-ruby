module HTTParty
  class Parser
    # We redefine it, so HTTParty can use MultiJson. By default HTTParty
    # hardcodes it to JSON from stdlib.
    def json
      Bugsnag::JSON.load(body)
    end
  end
end
