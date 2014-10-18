require 'spec_helper'

describe Jobs::NotifyFollowup, '#perform' do
  it 'uses the followup notifier mediator with the passed in followup_id' do
    followup = Fabricate(:followup)
    expect(Mediators::Followups::Notifier).to receive(:run).with(followup: followup)
    Jobs::NotifyFollowup.new.perform(followup.id)
  end
end
