module Jobs
  class Cleanup
    include Sidekiq::Worker
    # Scheduled job will run again in 12 hours if it fails:
    sidekiq_options retry: false

    def perform
      Mediators::Messages::Cleanup.run
    end
  end
end
