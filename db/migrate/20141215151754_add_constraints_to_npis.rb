class AddConstraintsToNpis < ActiveRecord::Migration
  def change
    execute " ALTER TABLE npis
              ADD CONSTRAINT npi_number_length CHECK (char_length(npi_number) = 10)
    "
  end

  def down
    execute " ALTER TABLE npis
              DROP CONSTRAINT npi_number_length,
    "
  end
end
