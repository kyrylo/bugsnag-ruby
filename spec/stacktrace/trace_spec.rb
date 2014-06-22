describe Bugsnag::Stacktrace::Trace do

  it "does not mark the top-most stacktrace line as inProject if out of project" do
    expect(Bugsnag::Notification).to receive(:deliver_exception_payload) do |endpoint, payload|
      exception = get_exception_from_payload(payload)
      expect(exception[:stacktrace].size).to be >= 1
      expect(exception[:stacktrace].first[:inProject]).to be_nil
    end

    Bugsnag.configuration.project_root = "/Random/location/here"
    Bugsnag.notify(BugsnagTestException.new("It crashed"))
  end

  it "marks the top-most stacktrace line as inProject if necessary" do
    expect(Bugsnag::Notification).to receive(:deliver_exception_payload) do |endpoint, payload|
      exception = get_exception_from_payload(payload)
      expect(exception[:stacktrace].size).to be >= 1
      expect(exception[:stacktrace].first[:inProject]).to eq(true)
    end

    Bugsnag.configuration.project_root = File.expand_path File.dirname(__FILE__)
    Bugsnag.notify(BugsnagTestException.new("It crashed"))
  end

  it "supports unix-style paths in backtraces" do
    ex = BugsnagTestException.new("It crashed")
    ex.set_backtrace([
        "/Users/james/app/spec/notification_spec.rb:419",
        "/Some/path/rspec/example.rb:113:in `instance_eval'"
      ])

    expect(Bugsnag::Notification).to receive(:deliver_exception_payload) do |endpoint, payload|
      exception = get_exception_from_payload(payload)
      expect(exception[:stacktrace].length).to eq(2)

      line = exception[:stacktrace][0]
      expect(line[:file]).to eq("/Users/james/app/spec/notification_spec.rb")
      expect(line[:lineNumber]).to eq(419)
      expect(line[:method]).to be nil

      line = exception[:stacktrace][1]
      expect(line[:file]).to eq("/Some/path/rspec/example.rb")
      expect(line[:lineNumber]).to eq(113)
      expect(line[:method]).to eq("instance_eval")
    end

    Bugsnag.notify(ex)
  end

  it "supports windows-style paths in backtraces" do
    ex = BugsnagTestException.new("It crashed")
    ex.set_backtrace([
        "C:/projects/test/app/controllers/users_controller.rb:13:in `index'",
        "C:/ruby/1.9.1/gems/actionpack-2.3.10/filters.rb:638:in `block in run_before_filters'"
      ])

    expect(Bugsnag::Notification).to receive(:deliver_exception_payload) do |endpoint, payload|
      exception = get_exception_from_payload(payload)
      expect(exception[:stacktrace].length).to eq(2)

      line = exception[:stacktrace][0]
      expect(line[:file]).to eq("C:/projects/test/app/controllers/users_controller.rb")
      expect(line[:lineNumber]).to eq(13)
      expect(line[:method]).to eq("index")

      line = exception[:stacktrace][1]
      expect(line[:file]).to eq("C:/ruby/1.9.1/gems/actionpack-2.3.10/filters.rb")
      expect(line[:lineNumber]).to eq(638)
      expect(line[:method]).to eq("block in run_before_filters")
    end

    Bugsnag.notify(ex)
  end

end
