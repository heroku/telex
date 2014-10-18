require "spec_helper"

describe Mediators::Followups::Notifier do
  before do
    allow(Mediators::Messages::UserUserFinder).to receive(:run)

    @user1, @user2 = 2.times.map { double('user', heroku_id: SecureRandom.uuid, email: Faker::Internet.email) }
    @message = double('message', title: Faker::Company.bs, id: SecureRandom.uuid, users: [@user1, @user2])
    @followup = double('followup', body: Faker::Company.bs, message: @message)
    @notifier = described_class.new(followup: @followup)
  end

  it 'uses the user finder update the users in case their emails have changed' do
    expect(Mediators::Messages::UserUserFinder).to receive(:run).with(target_id: @user1.heroku_id)
    expect(Mediators::Messages::UserUserFinder).to receive(:run).with(target_id: @user2.heroku_id)

    @notifier.call
  end

  it 'emails the users with the new followup' do
    @notifier.call
    ds = Mail::TestMailer.deliveries

    expect( ds.size                    ).to eq( 2 )
    expect( ds.map(&:to).flatten.sort  ).to eq( [@user1, @user2].map(&:email).sort )
    expect( ds.map(&:subject).uniq     ).to eq( [@message.title] )
    expect( ds.map(&:in_reply_to).uniq ).to eq( ["#{@message.id}@notifications.heroku.com"] )
  end
end
