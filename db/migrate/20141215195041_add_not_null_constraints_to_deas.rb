class AddNotNullConstraintsToDeas < ActiveRecord::Migration
  def up
    execute " ALTER TABLE deas
              ALTER COLUMN valid_in SET NOT NULL,
              ALTER COLUMN issued_date SET NOT NULL,
              ALTER COLUMN expiry_date SET NOT NULL
    "
  end

  def down
    execute " ALTER TABLE deas
              ALTER COLUMN valid_in DROP NOT NULL,
              ALTER COLUMN issued_date DROP NOT NULL,
              ALTER COLUMN expiry_date DROP NOT NULL
    "
  end
end
