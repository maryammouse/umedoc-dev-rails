class AddNotNullConstraintsToAddresses < ActiveRecord::Migration
  def up
    execute " ALTER TABLE addresses
              ALTER COLUMN mailing_name SET NOT NULL,
              ALTER COLUMN street_address_1 SET NOT NULL,
              ALTER COLUMN city SET NOT NULL,
              ALTER COLUMN state SET NOT NULL,
              ALTER COLUMN zip_code SET NOT NULL
    "
  end

  def down
    execute " ALTER TABLE addresses
              ALTER COLUMN mailing_name DROP NOT NULL,
              ALTER COLUMN street_address_1 DROP NOT NULL,
              ALTER COLUMN city DROP NOT NULL,
              ALTER COLUMN state DROP NOT NULL,
              ALTER COLUMN zip_code DROP NOT NULL
              "
  end
end
