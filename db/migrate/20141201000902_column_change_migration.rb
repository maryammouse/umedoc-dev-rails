class ColumnChangeMigration < ActiveRecord::Migration
  def up
    rename_column('credentials', 'location', 'valid_location')
    rename_column('credentials', 'from_date', 'first_issued_date')
  end

  def down
    rename_column('credentials', 'valid_location', 'location')
    rename_column('credentials', 'first_issued_date', 'from_date')
  end
end
