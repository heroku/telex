require "spec_helper"

describe Mediators::Messages::Creator do
  let(:producer) { Fabricate(:producer) }
  let(:user) { HerokuAPIMock.create_heroku_user }
  let(:app) { HerokuAPIMock.create_heroku_app(owner: user) }

  let(:creator_user) { described_class.new(producer: producer,
                                           title: Faker::Company.bs,
                                           body: Faker::Company.catch_phrase,
                                           action_label: 'Visit!',
                                           action_url: Faker::Internet.url,
                                           target_type: 'user',
                                           target_id: SecureRandom.uuid) }

  let(:creator_app) { described_class.new(producer: producer,
                                          title: "{{app}}",
                                          body: "{{app}}",
                                          action_label: 'Do something!',
                                          action_url: Faker::Internet.url,
                                          target_type: 'app',
                                          target_id: app.id) }

  it 'creates a message' do
    result = nil
    expect{ result = creator_user.call }.to change(Message, :count).by(1)
    expect(result).to be_instance_of(Message)
  end

  it 'emails' do
    expect(Jobs::MessagePlex).to receive(:perform_async).with(anything, false)
    creator_user.call
  end

  it 'templates app messages' do
    result = creator_app.call
    expect(result.title).to eq("example")
    expect(result.body).to eq("example")
  end

  it 'emails app messages' do
    expect(Jobs::MessagePlex).to receive(:perform_async).with(anything, false)
    creator_app.call
  end

  describe 'with a direwolf app' do
    let(:app) { HerokuAPIMock.create_heroku_app(owner: user, name: "direwolf-abcd") }

    it 'skips email' do
      expect(Jobs::MessagePlex).to receive(:perform_async).with(anything, true)
      creator_app.call
    end
  end

  it 'enqueues a MessagePlex job' do
    expect { creator_user.call }.to change(Jobs::MessagePlex.jobs, :size).by(1)
  end
end
