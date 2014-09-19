require 'sequel'

Sequel.migration do
  up do
    alter_table :builds do
      drop_column :key
    end
  end

  down do
    alter_table :builds do
      add_column :key, String
    end
  end

end
