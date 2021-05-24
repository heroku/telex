Sequel.migration do
  change do
    alter_table(:notifications) do
      set_column_allow_null :user_id
      add_column :recipient_id, :uuid, null: true
      add_foreign_key [:recipient_id], :recipients
    end
  end
end
