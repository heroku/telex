module Jobs
  class NotifyFollowup
    include Sidekiq::Worker

    def perform(followup_id)
      followup = Followup[id: followup_id]
      Mediators::Followups::Notifier.run(followup: followup)
    end
  end
end
