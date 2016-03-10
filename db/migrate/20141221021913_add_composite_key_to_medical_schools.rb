class AddCompositeKeyToMedicalSchools < ActiveRecord::Migration

  def up
    execute "
      alter table medical_schools
        drop constraint medical_schools_pkey,
        add primary key (name,country_iso)
    "
  end

  def down
    execute "
      alter table medical_schools
        drop constraint medical_schools_pkey,
        add primary key (name)
    "
  end

end
