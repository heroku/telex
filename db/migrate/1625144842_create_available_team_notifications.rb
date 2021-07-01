Sequel.migration do
  change do
    create_table(:available_team_notifications) do
      uuid :id, default: Sequel.function(:uuid_generate_v4), primary_key: true
      timestamptz :created_at, default: Sequel.function(:now), null: false
      timestamptz :updated_at
      text :team_manager_email, null: false
      text :team_notification_email, null: false
    end
  end
end
