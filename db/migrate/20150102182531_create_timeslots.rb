class CreateTimeslots < ActiveRecord::Migration
  def up
    execute "
      create table timeslots (
        id serial primary key,
        times tstzrange not null,
        doctor_id integer references doctors(id) not null,
        fee integer not null

        -- is_online boolean, '--' is to comment out the line
        -- is_physical boolean, I don't think we need this
        -- but I didn't want to delete without letting you know


        /* fee (you may want to get something working with just the times
           before worrying about this. first version of fee could be 
           just a number the doctor enters along with a time range, that 
           applies to all timeslots in that range
           i.e. I enter 08:00 - 18:00 on monday with fee 50
           I enter 18:00-22:00 on monday with fee 100
           I enter 22:00-08:00 on monday-tuesday with fee 200
           and so on..
           later version could have function in model to lookup fee from 
           a fee schedule based on time of day/day of week / is_holiday
        */



      );
    "
  end

  def down
    execute "
      drop table timeslots;
    "
  end

end
