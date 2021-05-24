Sequel.migration do
  change do
    create_table(:users) do
      uuid :id, default: Sequel.function(:uuid_generate_v4), primary_key: true
      uuid :heroku_id, null: false, unique: true
      timestamptz :created_at, default: Sequel.function(:now), null: false
      timestamptz :updated_at
      text :email, null: false
    end
  end
end
