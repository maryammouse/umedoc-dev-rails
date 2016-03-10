class RemoveCellnumberFromUser < ActiveRecord::Migration
  def change
    remove_column :users, :cellnumber, :integer
  end
end
