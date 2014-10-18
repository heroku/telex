require "spec_helper"

describe Endpoints::Producer::Messages do
  include Rack::Test::Methods

  def app
    Routes
  end

  before do
    header "Content-Type", "application/json"

    producer = Fabricate(:producer, api_key: 'foo')
    authorize producer.id, 'foo'

    @h_user1 = HerokuAPIMock.create_heroku_user
    Fabricate(:user, email: "outdated@email.com", heroku_id: @h_user1.heroku_id)
    @h_user2 = HerokuAPIMock.create_heroku_user
    heroku_app = HerokuAPIMock.create_heroku_app(owner: @h_user1, collaborators:[@h_user1, @h_user2])

    @message_body = {
      title: Faker::Company.bs,
      body: Faker::Company.bs,
      target: {type: 'app', id: heroku_app.id}
    }
  end

  def do_message_post
    response = nil
    Sidekiq::Testing.inline! do
      response = post '/producer/messages', MultiJson.encode(@message_body)
      expect(response.status).to eq(201)
    end
    MultiJson.decode(response.body)['id']
  end

  it 'works on the initial message' do
    # sanity checks
    expect(User.count).to eq(1)
    existing_user = User.first
    expect(existing_user.email).to eq("outdated@email.com")
    expect(@h_user1.email).to_not eq("outdated@email.com")
    expect(existing_user.heroku_id).to eq(@h_user1.heroku_id)

    # action
    do_message_post
    existing_user.reload

    # verification
    expect(last_response.status).to eq(201)
    expect(User.count).to eq(2)
    expect(existing_user.email).to eq(@h_user1.email)

    notifications = Notification.all
    users = User.all
    expect(notifications.map(&:user_id)).to match(users.map(&:id))
    expect(notifications.count).to eq(2)

    deliveries = Mail::TestMailer.deliveries
    expect(deliveries.map(&:to).flatten).to match(users.map(&:email))
    expect(deliveries.size).to eq(2)
  end

  it 'allows followup' do
    id = do_message_post
    Mail::TestMailer.deliveries.clear

    Sidekiq::Testing.inline! do
      response = post "/producer/messages/#{id}/followups", MultiJson.encode( {body: Faker::Company.bs} )
      expect(response.status).to eq(201)
    end

    users = User.all
    deliveries = Mail::TestMailer.deliveries
    expect(deliveries.map(&:to).flatten).to match(users.map(&:email))
    expect(deliveries.size).to eq(2)
  end
end
