Sequel.migration do
  change do
    alter_table(:messages) do
      add_column :action_label, :text
      add_column :action_url, :text
    end
  end
end
