module Middleware
  class Instrumentation
    def initialize(app)
      @app = app
    end

    def call(env)
      start = Time.now
      status, headers, response = @app.call(env)
      elapsed = (Time.now - start).to_f

      Telex::Sample.count "requests"
      Telex::Sample.count "requests.#{status}"
      Telex::Sample.count "requests.#{status / 10}x"
      Telex::Sample.measure "requests.latency", value: elapsed, unit: "s"

      [status, headers, response]
    end
  end
end
