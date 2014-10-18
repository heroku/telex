Sequel.migration do
  change do
    add_index :followups, :message_id

    add_index :messages, :producer_id
    add_index :messages, :target_id

    add_index :notifications, :user_id
    add_index :notifications, :message_id

    add_index :users, :heroku_id
  end
end
