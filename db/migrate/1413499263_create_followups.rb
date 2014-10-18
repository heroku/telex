Sequel.migration do
  change do
    create_table(:followups) do
      uuid         :id, default: Sequel.function(:uuid_generate_v4), primary_key: true
      uuid         :message_id, null: false
      timestamptz  :created_at, default: Sequel.function(:now), null: false

      text           :body,          null: false
    end
  end
end
