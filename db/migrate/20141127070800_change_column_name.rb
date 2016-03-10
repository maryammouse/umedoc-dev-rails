class ChangeColumnName < ActiveRecord::Migration
  def change
    rename_column :credentials, :expiry_data, :expiry_date
  end
end
