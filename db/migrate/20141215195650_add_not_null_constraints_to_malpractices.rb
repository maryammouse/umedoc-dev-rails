class AddNotNullConstraintsToMalpractices < ActiveRecord::Migration
  def up
    execute " ALTER TABLE malpractices
              ALTER COLUMN policy_number SET NOT NULL,
              ALTER COLUMN valid_location SET NOT NULL,
              ALTER COLUMN specialty SET NOT NULL,
              ALTER COLUMN in_person SET NOT NULL,
              ALTER COLUMN telemedicine SET NOT NULL,
              ALTER COLUMN policy_type SET NOT NULL,
              ALTER COLUMN coverage_amount SET NOT NULL
    "
  end

  def down
    execute " ALTER TABLE malpractices
              ALTER COLUMN policy_number DROP NOT NULL,
              ALTER COLUMN valid_location DROP NOT NULL,
              ALTER COLUMN specialty DROP NOT NULL,
              ALTER COLUMN in_person DROP NOT NULL,
              ALTER COLUMN telemedicine DROP NOT NULL,
              ALTER COLUMN policy_type DROP NOT NULL,
              ALTER COLUMN coverage_amount DROP NOT NULL
    "
  end
end
