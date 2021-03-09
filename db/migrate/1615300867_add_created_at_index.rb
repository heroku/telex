Sequel.migration do
  no_transaction
  change do
    alter_table(:messages) do
      add_index :created_at, concurrently: true
    end
  end
end
