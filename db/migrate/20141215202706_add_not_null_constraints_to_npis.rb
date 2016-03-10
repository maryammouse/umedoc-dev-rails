class AddNotNullConstraintsToNpis < ActiveRecord::Migration
  def up
    execute " ALTER TABLE npis
              ALTER COLUMN npi_number SET NOT NULL,
              ALTER COLUMN valid_in SET NOT NULL,
              ALTER COLUMN issued_date SET NOT NULL
    "
  end

  def down
    execute " ALTER TABLE npis
              ALTER COLUMN npi_number DROP NOT NULL,
              ALTER COLUMN valid_in DROP NOT NULL,
              ALTER COLUMN issued_date DROP NOT NULL
    "
  end
end
