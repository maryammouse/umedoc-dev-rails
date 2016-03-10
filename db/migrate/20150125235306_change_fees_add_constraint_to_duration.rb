class ChangeFeesAddConstraintToDuration < ActiveRecord::Migration
  def up
    execute "
      alter table fees add constraint duration_rounding_check check (extract(minute from duration) in (0,5,10,15,20,25,30,35,40,45,50,55))
    "
  end
  def down
    execute "
      alter table fees drop constraint duration_rounding_check
    "
  end
end

# code to round to nearest 5 mins in postgres, but probably best to do in in the model instead.
# select check (extract(minute from (round(extract(minute from interval '1 hour 17 min')/5)*(interval '5 min'))) in [0,5,10,15,20,25,30,35,40,45,50,55]);

