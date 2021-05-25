require "clockwork"
require_relative "application"
require "sidekiq/api"

module Clockwork
  every(10.seconds, "monitor_queue") do
    Thread.new do
      stats = Sidekiq::Stats.new
      Telex::Sample.sample "jobs.queue", value: stats.enqueued
      Telex::Sample.sample "jobs.queue-latency", value: "#{stats.default_queue_latency}s"
    end
  end

  every(12.hours, "monitor_queue") do
    Jobs::Cleanup.perform_async
  end
end
