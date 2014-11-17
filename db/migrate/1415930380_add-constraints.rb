Sequel.migration do
  change do
    alter_table(:followups) do
      add_foreign_key [:message_id], :messages
    end

    alter_table(:messages) do
      add_foreign_key [:producer_id], :producers
    end

    alter_table(:notifications) do
      add_index [:user_id, :message_id], unique: true
      add_foreign_key [:user_id],    :users
      add_foreign_key [:message_id], :messages
    end

    alter_table(:messages) do
      add_foreign_key [:producer_id], :producers
    end
  end
end
