Sequel.migration do
  change do
    create_table(:notifications) do
      uuid :id, default: Sequel.function(:uuid_generate_v4), primary_key: true
      timestamptz :created_at, default: Sequel.function(:now), null: false
      timestamptz :updated_at
      uuid :user_id, null: false
      uuid :message_id, null: false
    end
  end
end
