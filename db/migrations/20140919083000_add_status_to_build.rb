require 'sequel'

Sequel.migration do
  up do
    alter_table(:build) do
      add_column :status, Integer, :default => 1
      add_column :build_key, String
    end
  end

  down do
    remove_column :status
    remove_column :build_key
  end
end
