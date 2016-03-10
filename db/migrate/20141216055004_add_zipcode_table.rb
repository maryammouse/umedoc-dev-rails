class AddZipcodeTable < ActiveRecord::Migration
  def up
    execute "
        create table zip_codes (
          zip char(5) primary key,
          zip_type varchar(8) not null constraint zip_type_check check (zip_type in ('STANDARD',
                                                                            'PO BOX',
                                                                            'UNIQUE',
                                                                            'MILITARY')),
          primary_city varchar(32) not null,
          acceptable_cities varchar(255),
          unacceptable_cities varchar(255),
          state varchar(2) not null,
          county varchar(32),
          timezone varchar(32),
          area_codes varchar(32),
          lattitude float,
          longitude float,
          world_region varchar(2),
          country varchar(2),
          decommisioned boolean,
          estimated_population integer,
          notes varchar(255)
        );
    "
  end

  def down
    execute "
      drop table zip_codes;
    "
  end
end
