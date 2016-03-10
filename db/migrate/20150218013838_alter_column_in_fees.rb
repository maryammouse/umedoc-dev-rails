class AlterColumnInFees < ActiveRecord::Migration
  def up
    execute  <<-SQL
      alter table fees
      drop column time_range,
      add column timerange timerange not null

                SQL
  end

  def down
    execute  <<-SQL
      alter table fees
      drop column timerange,
      add column time_range timerange not null

                SQL
  end

end
