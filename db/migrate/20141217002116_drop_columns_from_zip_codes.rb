class DropColumnsFromZipCodes < ActiveRecord::Migration
  def up
    execute "
      alter table zip_codes
        drop if exists acceptable_cities,
        drop if exists unacceptable_cities,
        drop if exists world_region
        "
  end

  def down
    execute "
      alter table zip_codes
        add column acceptable_cities text,
        add column unacceptable_cities text,
        add column world_region varchar(2)
        "
  end
end
