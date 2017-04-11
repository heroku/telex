require 'spec_helper'

describe Jobs::MessagePlex, '#perform' do
  it 'uses the Plexer mediator with the passed in message_id' do
    message = Fabricate(:message)
    expect(Mediators::Messages::Plexer).to receive(:run).with(message: message, skip_email: false)
    Jobs::MessagePlex.new.perform(message.id, false)
  end
end
