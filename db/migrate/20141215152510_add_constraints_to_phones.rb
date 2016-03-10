class AddConstraintsToPhones < ActiveRecord::Migration
  def up
    execute " ALTER TABLE phones
              ADD CONSTRAINT number_length CHECK (char_length(number) = 10),
              ADD CONSTRAINT phone_type_within CHECK (phone_type in ('home', 'mobile', 'other'))
    "
  end

  def down
    execute " ALTER TABLE phones
              DROP CONSTRAINT phone_number_length,
              DROP CONSTRAINT phone_type_within
    "
  end
end
