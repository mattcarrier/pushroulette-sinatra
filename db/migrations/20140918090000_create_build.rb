require 'sequel'

Sequel.migration do
  up do
    create_table(:build) do
      primary_key :id
      String :key, :null=>false
    end
  end

  down do
    drop_table(:build)
  end
end
