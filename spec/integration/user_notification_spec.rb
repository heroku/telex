RSpec.describe Endpoints::ProducerAPI::Messages do
  include HerokuAPIMock
  include Rack::Test::Methods

  def app
    Routes
  end

  before do
    header "Content-Type", "application/json"

    producer = Fabricate(:producer, api_key: "foo")
    authorize(producer.id, "foo")

    @h_user = create_heroku_user
    Fabricate(:user, email: "outdated@email.com", heroku_id: @h_user.heroku_id)
    @unused_user = create_heroku_user
    Fabricate(:user, email: "outdated@email.com", heroku_id: @unused_user.heroku_id)

    @message_body = {
      title: Faker::Company.bs,
      body: Faker::Company.bs,
      target: {type: "user", id: @h_user.heroku_id}
    }
  end

  def do_post
    post "/producer/messages", MultiJson.encode(@message_body)
  end

  it "works" do
    # sanity checks
    expect(User.count).to eq(2)
    existing_user = User.first
    expect(existing_user.email).to eq("outdated@email.com")
    expect(@h_user.email).to_not eq("outdated@email.com")
    expect(existing_user.heroku_id).to eq(@h_user.heroku_id)

    # action
    Sidekiq::Testing.inline! do
      do_post
      existing_user.reload
    end

    # verification
    expect(last_response.status).to eq(201)
    expect(User.count).to eq(2)
    expect(existing_user.email).to eq(@h_user.email)

    notifications = Notification.all
    expect(notifications.first.user_id).to eq(existing_user.id)
    expect(notifications.count).to eq(1)

    deliveries = Mail::TestMailer.deliveries
    expect(deliveries.first.to).to match([@h_user.email])
    expect(deliveries.size).to eq(1)
  end
end
