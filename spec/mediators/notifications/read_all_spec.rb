RSpec.describe Mediators::Notifications::ReadAll, "#call" do

  let(:mediator) { described_class.new(user: user) }
  let(:user) { Fabricate(:user) }

  it "marks all recent notification as read" do
    count = 6
    notifications = Fabricate.times(count, :notification, user: user, read_at: nil)
    result = mediator.call
    expect(result).to eq(count)

    notifications.each do |note|
      note.reload
      expect(note.read_at).to be_within(1.second).of(Time.now)
    end
  end

  it "only marks notifications read for the user passed in" do
    to_be_read = Fabricate(:notification, user: user, read_at: nil)
    another_user = Fabricate(:user)
    to_not_be_read = Fabricate(:notification, user: another_user, read_at: nil)
    result = mediator.call
    expect(result).to eq(1)

    to_be_read.reload
    expect(to_be_read.read_at).to be_within(1.second).of(Time.now)

    to_not_be_read.reload
    expect(to_not_be_read.read_at).to be_nil
  end

  it "ignores notifications that are no longer valid" do
    one_month_ago = Date.today << 1
    notification = Fabricate(:notification, user: user, created_at: one_month_ago)
    result = mediator.call
    expect(result).to_not be_nil
    notification.reload
    expect(notification.read_at).to be_nil
  end
end
