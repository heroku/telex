require 'clockwork'
require_relative 'application'
require 'sidekiq/api'

module Clockwork
  every(10.seconds, 'monitor_queue') do
    Thread.new do
      stats = Sidekiq::Stats.new
      Telex::Sample.sample "jobs.queue", value: stats.enqueued
    end
  end
end
