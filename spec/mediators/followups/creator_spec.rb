require "spec_helper"

describe Mediators::Followups::Creator do
  before do
    @message = double('message', id: SecureRandom.uuid)
    @creator = described_class.new(message: @message,
                                   body: Faker::Company.catch_phrase)

  end

  it 'creates a followup pointing to the message' do
    result = nil
    expect{ result = @creator.call }.to change(Followup, :count).by(1)
    expect(result).to be_instance_of(Followup)
    expect(result.message_id).to eq(@message.id)
  end

  it 'enqueues a NotifyFollowup job' do
    expect { @creator.call }.to change(Jobs::NotifyFollowup.jobs, :size).by(1)
  end
end
