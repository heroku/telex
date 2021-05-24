Sequel.migration do
  up do
    execute 'create extension if not exists "uuid-ossp"'
    create_table(:producers) do
      uuid :id, default: Sequel.function(:uuid_generate_v4), primary_key: true
      text :name, null: false
      text :encrypted_api_key, null: false
      timestamptz :created_at, default: Sequel.function(:now), null: false
      timestamptz :updated_at
    end
  end

  down do
    execute 'drop extension "uuid-ossp"'
    execute "drop table producers"
  end
end
