class Notification < Sequel::Model
  many_to_one :user
  many_to_one :recipient
  many_to_one :message

  plugin :timestamps
  plugin :validation_helpers

  def self.find_by_notifiable_and_message(notifiable:, message:)
    key =
      case notifiable
      when User
        :user_id
      when Recipient
        :recipient_id
      else
        raise "Unrecognized notifiable %s" % notifiable.inspect
      end

    where(:message_id => message.id, key => notifiable.id)
  end

  def validate
    super
    if user
      validates_unique %i[user message]
    elsif recipient
      validates_unique %i[recipient message]
    end
  end

  def notifiable
    user || recipient
  end

  def notifiable=(notifiable)
    case notifiable
    when User
      self.user_id = notifiable.id
    when Recipient
      self.recipient_id = notifiable.id
    else
      raise "Unrecognized notifiable: %s" % notifiable.inspect
    end
  end
end
