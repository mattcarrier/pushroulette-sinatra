require 'sequel'

Sequel.migration do
  up do
    rename_table :build, :builds
  end

  down do
    rename_table :builds, :build
  end

end
