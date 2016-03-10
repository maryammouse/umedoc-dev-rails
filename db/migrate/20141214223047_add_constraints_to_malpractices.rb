class AddConstraintsToMalpractices < ActiveRecord::Migration
  def up
    execute " ALTER TABLE malpractices
              ADD CONSTRAINT policy_number_length CHECK (char_length(policy_number) <= 32),
              ADD CONSTRAINT valid_location_length CHECK (char_length(valid_location) = 2),
              ADD CONSTRAINT specialty_length CHECK (char_length(specialty) <= 64),
              ADD CONSTRAINT policy_type_within CHECK (policy_type in ('occurrence_based', 'claims_made'))
            "
  end

  def down
    execute " ALTER TABLE malpractices
              DROP CONSTRAINT policy_number_length,
              DROP CONSTRAINT valid_location_length
              DROP CONSTRAINT specialty_length,
              DROP CONSTRAINT policy_type_within
            "
  end
end
