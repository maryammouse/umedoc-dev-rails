class AddNotNullConstraintsToBoardCertifications < ActiveRecord::Migration
  def up
    execute " ALTER TABLE board_certifications
              ALTER COLUMN specialty SET NOT NULL,
              ALTER COLUMN board_name SET NOT NULL,
              ALTER COLUMN issue_date SET NOT NULL,
              ALTER COLUMN expiry_date SET NOT NULL,
              ALTER COLUMN certification_number SET NOT NULL
    "
  end

  def down
    execute " ALTER TABLE board_certifications
              ALTER COLUMN specialty DROP NOT NULL,
              ALTER COLUMN board_name DROP NOT NULL,
              ALTER COLUMN issue_date DROP NOT NULL,
              ALTER COLUMN expiry_date DROP NOT NULL,
              ALTER COLUMN certification_number DROP NOT NULL
    "
  end
end
