class RemoveValidInFromMedicalLicense < ActiveRecord::Migration
  def up
    execute  <<-SQL
      alter table medical_licenses
        drop constraint valid_in_length,
        drop column valid_in;

                SQL
  end

  def down
    execute  <<-SQL
      alter table medical_licenses
        add column valid_in varchar(255),
        add constraint valid_in_length CHECK (char_length(valid_in::text) <= 2);

                SQL
  end
end
