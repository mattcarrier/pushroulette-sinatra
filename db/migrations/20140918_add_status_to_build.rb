require 'sequel'

Sequel.migration do
  up do
    add_column :status, String
  end

  down do
  end
end
