class AlterColumnTypesForPromotions < ActiveRecord::Migration
  def up
    execute " ALTER TABLE promotions
              ALTER COLUMN start_time TYPE time,
              ALTER COLUMN start_time SET DEFAULT '00:00:00',
              ALTER COLUMN end_time TYPE time,
              ALTER COLUMN end_time SET DEFAULT '24:00:00',
              ALTER COLUMN timezone SET DEFAULT 'Pacific Time (US & Canada)'
    "
  end

  def down
    execute " ALTER TABLE promotions
              ALTER COLUMN start_time TYPE timetz,
              ALTER COLUMN start_time DROP DEFAULT,
              ALTER COLUMN start_time SET DEFAULT '00:00:00-08',
              ALTER COLUMN end_time TYPE timetz,
              ALTER COLUMN end_time DROP DEFAULT,
              ALTER COLUMN end_time SET DEFAULT '24:00:00-08',
              ALTER COLUMN timezone DROP DEFAULT
    "
  end
end
