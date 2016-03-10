class AddCellnumberToUser < ActiveRecord::Migration
  def change
    add_column :users, :cellnumber, :string
  end
end
