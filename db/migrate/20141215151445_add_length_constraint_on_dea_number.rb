class AddLengthConstraintOnDeaNumber < ActiveRecord::Migration
  def up
    execute " ALTER TABLE deas
              ADD CONSTRAINT dea_number_length CHECK (char_length(dea_number) = 9),
              ADD CONSTRAINT valid_in_length CHECK (char_length(valid_in) = 2)
              "
  end

  def down
    execute " ALTER TABLE deas
              DROP CONSTRAINT dea_number_length
              DROP CONSTRAINT valid_in_length"
  end
end
