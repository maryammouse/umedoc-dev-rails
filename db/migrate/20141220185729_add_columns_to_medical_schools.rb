class AddColumnsToMedicalSchools < ActiveRecord::Migration
  def up
    execute "
      alter table medical_schools
        add city varchar(255) not null,
        add country_iso varchar(2) references countries(iso) not null
    "
  end
  def down
    execute "
      alter table medical_schools
        drop city if exists
        drop country_iso if_exists
    "

  end
end
