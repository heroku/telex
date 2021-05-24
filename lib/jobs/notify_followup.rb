module Jobs
  class NotifyFollowup
    include Sidekiq::Worker

    sidekiq_options retry: 10

    # The default retry is exponential
    sidekiq_retry_in do |count|
      200 * (count + 1) # (i.e. 200, 400, 600, 800... seconds)
    end

    def perform(followup_id)
      followup = Followup[id: followup_id]
      Mediators::Followups::Notifier.run(followup: followup)
    end
  end
end
