Sequel.migration do
  change do
    create_table(:team_notifications) do
      uuid :id, default: Sequel.function(:uuid_generate_v4), primary_key: true
      timestamptz :created_at, default: Sequel.function(:now), null: false
      timestamptz :updated_at
      uuid :message_id, null: false
      text :email, null: false
    end

    add_index :team_notifications, :message_id

    alter_table(:notifications) do
      add_foreign_key [:message_id], :messages
    end
  end
end
