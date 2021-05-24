require "active_support/core_ext/numeric/time"

class Redis
  module Retry
    class Error < StandardError; end

    def redis_retry(**opts, &block)
      opts[:attempts] ||= 0
      opts[:finish_time] ||= retry_window.seconds.from_now
      log(opts[:attempts]) if opts[:attempts] > 0

      yield.tap do
        log(opts[:attempts], successful: true)
      end
    rescue Redis::BaseConnectionError
      opts[:attempts] += 1

      if Time.now < opts[:finish_time]
        sleep(0.1)
        redis_retry(opts, &block)
      else
        raise Error, "Failed to connect to Redis after #{retry_window} seconds."
      end
    end

    def retry_window
      ENV.fetch("REDIS_RETRY_IN_SECONDS", 20).to_i
    end

    def log(attempts, **opts)
      Pliny.log({redis_retry: true, attempt: attempts}.merge(opts))
    end
  end
end
