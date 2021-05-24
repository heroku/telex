module Telex
  class SidekiqInstrumenter
    def call(worker, msg, queue, &block)
      Telex::Sample.count("jobs.locked")
      Telex::Sample.measure("jobs.duration", &block)
      Telex::Sample.count("jobs.success")
    rescue Exception
      Telex::Sample.count("jobs.failure")
      raise
    end
  end
end
