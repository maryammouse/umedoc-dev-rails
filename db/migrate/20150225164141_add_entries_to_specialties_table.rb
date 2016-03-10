class AddEntriesToSpecialtiesTable < ActiveRecord::Migration
  def up
    execute  <<-SQL
      insert into specialties values('General Practice');
      insert into specialties values('None');
                SQL
  end

  def down
    execute  <<-SQL
      delete from specialties where name='General Practice';
      delete from specialties where name='None';
                SQL
  end
end
