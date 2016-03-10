class ChangeAuthyIdToString < ActiveRecord::Migration
  def up
    execute  <<-SQL
      alter table users
        alter column authy_id set data type varchar(255);
                SQL
  end

  def down
      raise ActiveRecord::IrreversibleMigration
  end
end
