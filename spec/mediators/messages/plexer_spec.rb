require "spec_helper"

include Mediators::Messages

describe Plexer, '#call' do
  before do
    @message = Fabricate(:message, target_type: 'app')
    @plexer = Plexer.new(message: @message, skip_email: false)
    @uwrs = Array.new(2) { UserWithRole.new(:whatever, Fabricate(:user)) }
  end

  it 'uses the user finder to set @users_with_role' do
    user_finder = double('user finder')
    @plexer.user_finder = user_finder

    expect(@plexer.users_with_role).to eq([])
    expect(user_finder).to receive(:call).and_return( @uwrs )
    @plexer.call
    expect(@plexer.users_with_role).to eq(@uwrs)
  end

  it 'picks the appropriate user finder' do
    allow(@message).to receive(:target_type).and_return('app')
    plexer = Plexer.new(message: @message, skip_email: false)
    expect(plexer.user_finder).to be_instance_of(Mediators::Messages::AppUserFinder)
  end

  it 'picks the email finder on email' do
    allow(@message).to receive(:target_type).and_return('email')
    plexer = Plexer.new(message: @message, skip_email: false)
    expect(plexer.user_finder).to be_instance_of(Mediators::Messages::EmailUserFinder)
  end

  it 'creates a Notificaton for each user' do
    @plexer.user_finder = double('user finder', call: @uwrs)

    expect(Mediators::Notifications::Creator).to receive(:run).with(
      message: @message, notifiable: @uwrs[0].user,
      skip_email: false
    )
    expect(Mediators::Notifications::Creator).to receive(:run).with(
      message: @message, notifiable: @uwrs[1].user,
      skip_email: false
    )
    @plexer.call
  end
end
