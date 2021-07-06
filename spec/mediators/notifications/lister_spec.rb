RSpec.describe Mediators::Notifications::Lister, "#call" do
  let(:lister) { described_class.new(user: @user) }

  before do
    @user = Fabricate(:user)
  end

  context "a user with no notifications" do
    it "returns an empty array" do
      expect(lister.call).to eq([])
    end
  end

  context "a user with notificatons" do
    before do
      @p1 = Fabricate(:producer)
      @m1 = Fabricate(:message, producer: @p1)
      @m2 = Fabricate(:message, producer: @p1)
      @f1 = Fabricate(:followup, message: @m1)
      @n1 = Fabricate(:notification, user: @user, message: @m1, created_at: DateTime.now - 1)
      @n2 = Fabricate(:notification, user: @user, message: @m2, created_at: DateTime.now)
    end

    it "returns the notifications in a sorted array" do
      expect(@n2.created_at).to be > @n1.created_at
      expect(lister.call).to eq([@n2, @n1])
    end

    it "does not include notifications for older than one month" do
      @m3 = Fabricate(:message, producer: @p1)
      @n3 = Fabricate(:notification, user: @user, message: @m3, created_at: DateTime.now - 35)
      expect(lister.call).to_not include(@n3)
    end

    it "does not include notifications for other users" do
      user2 = Fabricate(:user)
      note = Fabricate(:notification, user: user2)

      expect(lister.call).to_not include(note)
    end

    it "only makes one query even when the associated parts are touched" do
      selects = count_selects {
        result = lister.call
        result.first.message
        result.first.message.body
        result.first.message.title
        result.first.message.followup
        result.last.message
        result.last.message.body
        result.last.message.title
        result.last.message.followup
        result.last.message.followup.first.body
      }

      expect(selects).to eq(1)
    end
  end
end
