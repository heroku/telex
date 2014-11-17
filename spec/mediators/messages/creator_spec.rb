require "spec_helper"

describe Mediators::Messages::Creator do
  before do
    producer = Fabricate(:producer)
    @creator = described_class.new(producer: producer,
                                  title: Faker::Company.bs,
                                  body: Faker::Company.catch_phrase,
                                  target_type: 'user',
                                  target_id: SecureRandom.uuid)

  end

  it 'creates a message' do
    result = nil
    expect{ result = @creator.call }.to change(Message, :count).by(1)
    expect(result).to be_instance_of(Message)
  end

  it 'enqueues a MessagePlex job' do
    expect { @creator.call }.to change(Jobs::MessagePlex.jobs, :size).by(1)
  end
end
